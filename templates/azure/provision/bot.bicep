@secure()
param provisionParameters object

var resourceBaseName = provisionParameters.resourceBaseName
var botServiceName = contains(provisionParameters, 'botServiceName') ? provisionParameters['botServiceName'] : '${resourceBaseName}' // Try to read name for Azure Bot Service from parameters
var serverfarmsName = contains(provisionParameters, 'botServerfarmsName') ? provisionParameters['botServerfarmsName'] : '${resourceBaseName}bot' // Try to read name for App Service Plan from parameters
var webAppSKU = contains(provisionParameters, 'botWebAppSKU') ? provisionParameters['botWebAppSKU'] : 'B1' // Try to read SKU for Azure Web App from parameters
var webAppName = contains(provisionParameters, 'botSitesName') ? provisionParameters['botSitesName'] : '${resourceBaseName}bot' // Try to read name for Azure Web App from parameters

var subscriptionId = provisionParameters['existingSubscription']
var resourceGroupName = provisionParameters['existingResourceGroup']

// Register your web service as a bot with the Bot Framework
resource botService 'Microsoft.BotService/botServices@2021-03-01' existing = {
  name: botServiceName
  scope: resourceGroup(subscriptionId, resourceGroupName)
}

// Web App that hosts your bot
resource webApp 'Microsoft.Web/sites@2021-02-01' existing = {
  name: webAppName
  scope: resourceGroup(subscriptionId, resourceGroupName)
}

output botWebAppSKU string = webAppSKU
output botWebAppName string = webAppName
output botDomain string = webApp.properties.defaultHostName
output appServicePlanName string = serverfarmsName
output botServiceName string = botServiceName
output botWebAppResourceId string = webApp.id
output botWebAppEndpoint string = 'https://${webApp.properties.defaultHostName}'
