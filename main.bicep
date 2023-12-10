param containerRegistryName string 
param containerRegistryImageVersion string 
param appServicePlanName string
param siteName string
param location string
param containerRegistryImageName string = 'flask-demo'

param keyVaultName string
param keyVaultSecretNameACRUsername string = 'acr-username'
param keyVaultSecretNameACRPassword1 string = 'acr-password1'

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
 }

 // Azure Container Registry module
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
 }

module serverfarm 'modules/web/serverfarm/main.bicep' = {
  name: '${uniqueString(deployment().name)}-asp'
  params: {
    name: appServicePlanName
    location: location
    sku: {
      capacity: '1'
      family: 'B'
      name: 'B1'
      size: 'B1'
      tier: 'Basic'
    } 
    reserved: true 
  }
}

module website 'modules/web/site/main.bicep' = {
  name: '${uniqueString(deployment().name)}-site'
  dependsOn: [
    serverfarm
    acr
    keyvault
  ]
  params: {
    name: siteName
    location: location
    kind: 'app'
    serverFarmResourceId: resourceId('Microsoft.Web/serverfarms', appServicePlanName)
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${containerRegistryImageName}:${containerRegistryImageVersion}'
      appCommandLine: ''
    }
    appSettingsKeyValuePairs: {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: false
      DOCKER_REGISTRY_SERVER_URL: '${containerRegistryName}.azurecr.io'
      dockerRegistryServerUserName: keyvault.getSecret(keyVaultSecretNameACRUsername)
      dockerRegistryServerPassword: keyvault.getSecret(keyVaultSecretNameACRPassword1)
    }
  }
}
