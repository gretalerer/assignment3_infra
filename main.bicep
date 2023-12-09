param containerRegistryName string
param containerRegistryImageName string
param containerRegistryImageVersion string = 'main-latest'
param appServicePlanName string
param siteName string
param location string = resourceGroup().location
param keyVaultName string
param keyVaultSecretNameACRUsername string = 'acr-username'
param keyVaultSecretNameACRPassword1 string = 'acr-password1'
param keyVaultSecretNameACRPassword2 string = 'acr-password2'

module containerRegistry 'modules/container-registry/registry/main.bicep' = {
  name: 'containerRegistryName'
  params: {
    name: containerRegistryName 
    location: location
    acrAdminUserEnabled: true
    adminCredentialsKeyVaultResourceId: resourceId('Microsoft.KeyVault/vaults', keyVaultName)
    adminCredentialsKeyVaultSecretUserName: keyVaultSecretNameACRUsername
    adminCredentialsKeyVaultSecretUserPassword1: keyVaultSecretNameACRPassword1
    adminCredentialsKeyVaultSecretUserPassword2: keyVaultSecretNameACRPassword2
  }
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
      DOCKER_REGISTRY_SERVER_USERNAME: keyVaultSecretNameACRUsername  
      DOCKER_REGISTRY_SERVER_PASSWORD: keyVaultSecretNameACRPassword1 
    }
  }
}
