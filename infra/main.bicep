metadata description = 'Azure Infrastructure for Todo Management App with PostgreSQL and Container Apps'

param location string = 'japaneast'
param environment string = 'dev'
param projectName string = 'todomanagement'

// PostgreSQL parameters
param postgresqlVersion string = '17'
param postgresqlAdminUsername string = 'postgres'
@minLength(8)
@secure()
param postgresqlAdminPassword string

// Virtual Network
param vnetAddressPrefix string = '10.0.0.0/16'
param postgresSubnetPrefix string = '10.0.1.0/24'
param containerAppSubnetPrefix string = '10.0.2.0/24'
param privateEndpointSubnetPrefix string = '10.0.3.0/24'

var vnetName = 'vnet-${projectName}-${environment}'
var postgresSubnetName = 'subnet-postgres-${environment}'
var containerAppSubnetName = 'subnet-ca-${environment}'
var privateEndpointSubnetName = 'subnet-pe-${environment}'
var postgresServerName = 'postgres-${projectName}-${uniqueString(resourceGroup().id)}'
var containerRegistryName = 'acr${projectName}${uniqueString(resourceGroup().id)}'
var containerAppEnvName = 'cae-${projectName}-${environment}'
var databaseName = 'tododb'

// Create Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: postgresSubnetName
        properties: {
          addressPrefix: postgresSubnetPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: containerAppSubnetName
        properties: {
          addressPrefix: containerAppSubnetPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Create Private DNS Zone for PostgreSQL
resource postgresPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.postgres.database.azure.com'
  location: 'global'
}

// Link Private DNS Zone to VNet
resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: postgresPrivateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Create PostgreSQL Flexible Server
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: postgresServerName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: postgresqlVersion
    administratorLogin: postgresqlAdminUsername
    administratorLoginPassword: postgresqlAdminPassword
    network: {
      delegatedSubnetResourceId: '${vnet.id}/subnets/${postgresSubnetName}'
      privateDnsZoneArmResourceId: postgresPrivateDnsZone.id
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    storage: {
      storageSizeGB: 32
    }
    highAvailability: {
      mode: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Enabled'
    }
  }
}

// Create PostgreSQL Database
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgresqlServer
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Configure PostgreSQL firewall rule for Container App subnet
resource fwRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: postgresqlServer
  name: 'allow-container-apps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

// Azure Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        status: 'enabled'
        days: 30
      }
    }
  }
}

// Create User Assigned Identity for Container Apps
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uai-${projectName}-${environment}'
  location: location
}

// Create Private Endpoint for ACR
var acrPrivateEndpointName = 'pe-acr-${projectName}-${environment}'
var acrPrivateDnsZoneName = 'privatelink.azurecr.io'
var acrPrivateDnsZoneGroupName = 'default'

resource acrPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: acrPrivateDnsZoneName
  location: 'global'
}

resource acrPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: acrPrivateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: acrPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${privateEndpointSubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'acr-connection'
        properties: {
          privateLinkServiceId: containerRegistry.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

resource acrPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: acrPrivateEndpoint
  name: acrPrivateDnsZoneGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: acrPrivateDnsZone.id
        }
      }
    ]
  }
}

// RBAC Role Assignment: AcrPull for User Assigned Identity
// NOTE: Role assignment will be created via Azure CLI after infrastructure deployment
// This is due to potential role definition availability issues in some subscriptions
// To assign the role manually, run:
// az role assignment create --assignee-object-id <uai-principal-id> --role "AcrPull" --scope <acr-id>
// Uncomment the resource below if you have subscription-level permissions:
/*
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, userAssignedIdentity.id, 'AcrPull')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4694-a41a-4ac8986f8c5b')
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    userAssignedIdentity
  ]
}
*/

// Create Log Analytics Workspace for Container App Environment
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${projectName}-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Create Container App Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: '${vnet.id}/subnets/${containerAppSubnetName}'
      internal: false
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// Output important values
output vnetId string = vnet.id
output postgresqlServerId string = postgresqlServer.id
output postgresqlServerName string = postgresqlServer.name
output postgresqlHostname string = postgresqlServer.properties.fullyQualifiedDomainName
output databaseName string = databaseName
output containerAppEnvironmentId string = containerAppEnvironment.id
output containerAppEnvironmentName string = containerAppEnvironment.name
output containerRegistryId string = containerRegistry.id
output containerRegistryName string = containerRegistry.name
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output postgresSubnetId string = '${vnet.id}/subnets/${postgresSubnetName}'
output containerAppSubnetId string = '${vnet.id}/subnets/${containerAppSubnetName}'
output privateEndpointSubnetId string = '${vnet.id}/subnets/${privateEndpointSubnetName}'
output userAssignedIdentityId string = userAssignedIdentity.id
output userAssignedIdentityClientId string = userAssignedIdentity.properties.clientId
output userAssignedIdentityPrincipalId string = userAssignedIdentity.properties.principalId
output acrPrivateEndpointId string = acrPrivateEndpoint.id
output acrPrivateDnsZoneId string = acrPrivateDnsZone.id
