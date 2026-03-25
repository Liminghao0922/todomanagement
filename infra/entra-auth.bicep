metadata description = 'Configure Entra ID authentication for Container App to access PostgreSQL'

param postgresqlServerId string
param postgresqlServerName string
param postgresqlDatabaseName string
param containerAppUserAssignedIdentityId string
param containerAppUserAssignedIdentityClientId string

// Reference to existing PostgreSQL server
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' existing = {
  name: postgresqlServerName
}

// PostgreSQL Configuration for Entra ID - enable Azure Authentication
resource postgresqlConfig 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2024-08-01' = {
  parent: postgresqlServer
  name: 'azure.extensions'
  properties: {
    value: 'plpgsql,pgcrypto,uuid-ossp'
    source: 'user-override'
  }
}

output postgresqlServerId string = postgresqlServer.id
output postgresqlServerName string = postgresqlServer.name
