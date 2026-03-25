metadata description = 'Deploy a Container App with Entra ID-based PostgreSQL connectivity'

param containerAppName string
param containerAppEnvironmentId string
param containerRegistryLoginServer string
param containerImage string
param postgresqlHostname string
param postgresqlDatabaseName string
param containerAppUserAssignedIdentityId string
param containerAppUserAssignedIdentityClientId string
param location string = 'japaneast'

// User-assigned managed identity for the Container App
resource containerAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uai-${containerAppName}'
  location: location
}

// Container App with environment variables for PostgreSQL connection
resource containerApp 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerAppIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          loginServer: containerRegistryLoginServer
          identity: containerAppIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          image: containerImage
          name: containerAppName
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'DATABASE_HOST'
              value: postgresqlHostname
            }
            {
              name: 'DATABASE_NAME'
              value: postgresqlDatabaseName
            }
            {
              name: 'DATABASE_PORT'
              value: '5432'
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: containerAppIdentity.properties.clientId
            }
            {
              name: 'MANAGED_IDENTITY_ENABLED'
              value: 'true'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
  dependsOn: [
    containerAppIdentity
  ]
}

output containerAppId string = containerApp.id
output containerAppName string = containerApp.name
output containerAppIdentityId string = containerAppIdentity.id
output containerAppIdentityClientId string = containerAppIdentity.properties.clientId
output containerAppIdentityPrincipalId string = containerAppIdentity.properties.principalId
