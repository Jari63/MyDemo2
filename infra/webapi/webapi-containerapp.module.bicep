@description('The location for the resource(s) to be deployed.')
param location string = resourceGroup().location

param aca_env_outputs_azure_container_apps_environment_default_domain string

param aca_env_outputs_azure_container_apps_environment_id string

param webapi_containerimage string

param webapi_identity_outputs_id string

param webapi_containerport string

param dbserver_outputs_sqlserverfqdn string

param webapi_identity_outputs_clientid string

param aca_env_outputs_azure_container_registry_endpoint string

param aca_env_outputs_azure_container_registry_managed_identity_id string

resource webapi 'Microsoft.App/containerApps@2025-02-02-preview' = {
  name: 'webapi'
  location: location
  properties: {
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: int(webapi_containerport)
        transport: 'http'
      }
      registries: [
        {
          server: aca_env_outputs_azure_container_registry_endpoint
          identity: aca_env_outputs_azure_container_registry_managed_identity_id
        }
      ]
      runtime: {
        dotnet: {
          autoConfigureDataProtection: true
        }
      }
    }
    environmentId: aca_env_outputs_azure_container_apps_environment_id
    template: {
      containers: [
        {
          image: webapi_containerimage
          name: 'webapi'
          env: [
            {
              name: 'OTEL_DOTNET_EXPERIMENTAL_OTLP_EMIT_EXCEPTION_LOG_ATTRIBUTES'
              value: 'true'
            }
            {
              name: 'OTEL_DOTNET_EXPERIMENTAL_OTLP_EMIT_EVENT_LOG_ATTRIBUTES'
              value: 'true'
            }
            {
              name: 'OTEL_DOTNET_EXPERIMENTAL_OTLP_RETRY'
              value: 'in_memory'
            }
            {
              name: 'ASPNETCORE_FORWARDEDHEADERS_ENABLED'
              value: 'true'
            }
            {
              name: 'HTTP_PORTS'
              value: webapi_containerport
            }
            {
              name: 'ConnectionStrings__mydemo2Db'
              value: 'Server=tcp:${dbserver_outputs_sqlserverfqdn},1433;Encrypt=True;Authentication="Active Directory Default";Database=mydemo2Db'
            }
            {
              name: 'MYDEMO2DB_HOST'
              value: dbserver_outputs_sqlserverfqdn
            }
            {
              name: 'MYDEMO2DB_PORT'
              value: '1433'
            }
            {
              name: 'MYDEMO2DB_URI'
              value: 'mssql://${dbserver_outputs_sqlserverfqdn}:1433/mydemo2Db'
            }
            {
              name: 'MYDEMO2DB_JDBCCONNECTIONSTRING'
              value: 'jdbc:sqlserver://${dbserver_outputs_sqlserverfqdn}:1433;database=mydemo2Db;encrypt=true;trustServerCertificate=false'
            }
            {
              name: 'MYDEMO2DB_DATABASENAME'
              value: 'mydemo2Db'
            }
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: webapi_identity_outputs_clientid
            }
            {
              name: 'AZURE_TOKEN_CREDENTIALS'
              value: 'ManagedIdentityCredential'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
      }
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${webapi_identity_outputs_id}': { }
      '${aca_env_outputs_azure_container_registry_managed_identity_id}': { }
    }
  }
}