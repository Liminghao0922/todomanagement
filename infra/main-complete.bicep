metadata description = 'Complete infrastructure deployment for Todo Management App with all modules'

param location string = 'japaneast'
param environment string = 'dev'
param projectName string = 'todomanagement'
param postgresqlVersion string = '17'
param postgresqlAdminUsername string = 'postgres'

@minLength(8)
@secure()
param postgresqlAdminPassword string

@minLength(8)
@secure()
param containerAppApiImage string

param vnetAddressPrefix string = '10.0.0.0/16'
param postgresSubnetPrefix string = '10.0.1.0/24'
param containerAppSubnetPrefix string = '10.0.2.0/24'

// Deploy main infrastructure
module infrastructure './main.bicep' = {
  name: 'infrastructure-deployment'
  params: {
    location: location
    environment: environment
    projectName: projectName
    postgresqlVersion: postgresqlVersion
    postgresqlAdminUsername: postgresqlAdminUsername
    postgresqlAdminPassword: postgresqlAdminPassword
    vnetAddressPrefix: vnetAddressPrefix
    postgresSubnetPrefix: postgresSubnetPrefix
    containerAppSubnetPrefix: containerAppSubnetPrefix
  }
}

// Create managed identity for Container App
resource containerAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uai-ca-${projectName}-${environment}'
  location: location
}

// Grant managed identity access to ACR
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(resourceGroup().id, containerAppIdentity.id, 'AcrPull')
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951eea-edd1-4ac2-b5a7-dff2ec22b6d9' // ACR Pull role
    principalId: containerAppIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deploy Container App with Entra ID authentication
module containerAppDeployment './container-app.bicep' = {
  name: 'container-app-deployment'
  params: {
    containerAppName: 'ca-${projectName}-api-${environment}'
    containerAppEnvironmentId: infrastructure.outputs.containerAppEnvironmentId
    containerRegistryLoginServer: infrastructure.outputs.containerRegistryLoginServer
    containerImage: containerAppApiImage
    postgresqlHostname: infrastructure.outputs.postgresqlHostname
    postgresqlDatabaseName: infrastructure.outputs.databaseName
    containerAppUserAssignedIdentityId: containerAppIdentity.id
    containerAppUserAssignedIdentityClientId: containerAppIdentity.properties.clientId
    location: location
  }
  dependsOn: [
    acrRoleAssignment
  ]
}

// Output all important references
output infrastructureOutputs object = {
  vnetId: infrastructure.outputs.vnetId
  postgresqlServerId: infrastructure.outputs.postgresqlServerId
  postgresqlServerName: infrastructure.outputs.postgresqlServerName
  postgresqlHostname: infrastructure.outputs.postgresqlHostname
  databaseName: infrastructure.outputs.databaseName
  containerAppEnvironmentId: infrastructure.outputs.containerAppEnvironmentId
  containerAppEnvironmentName: infrastructure.outputs.containerAppEnvironmentName
  containerRegistryId: infrastructure.outputs.containerRegistryId
  containerRegistryName: infrastructure.outputs.containerRegistryName
  containerRegistryLoginServer: infrastructure.outputs.containerRegistryLoginServer
  postgresSubnetId: infrastructure.outputs.postgresSubnetId
  containerAppSubnetId: infrastructure.outputs.containerAppSubnetId
}

output containerAppOutputs object = {
  containerAppId: containerAppDeployment.outputs.containerAppId
  containerAppName: containerAppDeployment.outputs.containerAppName
  containerAppIdentityId: containerAppDeployment.outputs.containerAppIdentityId
  containerAppIdentityClientId: containerAppDeployment.outputs.containerAppIdentityClientId
  containerAppIdentityPrincipalId: containerAppDeployment.outputs.containerAppIdentityPrincipalId
}

output managedIdentityInfo object = {
  identityId: containerAppIdentity.id
  identityName: containerAppIdentity.name
  clientId: containerAppIdentity.properties.clientId
  principalId: containerAppIdentity.properties.principalId
  tenantId: containerAppIdentity.properties.tenantId
}
