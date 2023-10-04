targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

// azure open ai 
@description('Location for the OpenAI resource group')
@allowed(['canadaeast', 'eastus', 'francecentral', 'japaneast', 'northcentralus'])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAILocation string

param openAISku string = 'S0'
param openAIApiVersion string = '2023-03-15-preview'

param chatGptDeploymentCapacity int = 30
param chatGptDeploymentName string = 'chat-gpt-35-turbo'
param chatGptModelName string = 'gpt-35-turbo'
param chatGptModelVersion string = '0613'
param embeddingDeploymentName string = 'embedding'
param embeddingDeploymentCapacity int = 10
param embeddingModelName string = 'text-embedding-ada-002'

param formRecognizerSkuName string = 'S0'
param searchServiceIndexName string = 'azure-chat'
param searchServiceSkuName string = 'standard'
param searchServiceAPIVersion string = '2023-07-01-Preview'

param authGithubId string = ''
@secure()
param authGithubSecret string = ''
param azureAdTenantId string = ''
param azureAdClientId string = ''
@secure()
param azureAdClientSecret string = ''
param azureAdAllowedPrincipals string = ''
param adminEmailAddress string = ''

param resourceGroupName string = ''

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = { 'azd-env-name': name }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : 'rg-${name}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  name: 'all-resources'
  scope: rg
  params: {
    name: name
    resourceToken: resourceToken
    tags: tags
    openai_api_version: openAIApiVersion
    openAiResourceGroupLocation: openAILocation
    openAiSkuName: openAISku
    chatGptDeploymentCapacity: chatGptDeploymentCapacity
    chatGptDeploymentName: chatGptDeploymentName
    chatGptModelName: chatGptModelName
    chatGptModelVersion: chatGptModelVersion
    embeddingDeploymentName: embeddingDeploymentName
    embeddingDeploymentCapacity: embeddingDeploymentCapacity
    embeddingModelName: embeddingModelName
    formRecognizerSkuName: formRecognizerSkuName
    searchServiceIndexName: searchServiceIndexName
    searchServiceSkuName: searchServiceSkuName
    searchServiceAPIVersion: searchServiceAPIVersion
    authGithubId: authGithubId
    authGithubSecret: authGithubSecret
    azureAdTenantId: azureAdTenantId
    azureAdClientId: azureAdClientId
    azureAdClientSecret: azureAdClientSecret
    azureAdAllowedPrincipals: azureAdAllowedPrincipals
    adminEmailAddress: adminEmailAddress
    location: location
  }
}

output APP_URL string = resources.outputs.url
output APP_REDIRECT_URI_GITHUB string = '${resources.outputs.url}/api/auth/callback/github'
output APP_REDIRECT_URI_AZURE_AD string = '${resources.outputs.url}/api/auth/callback/azure-ad'
output AZURE_WEBAPP_RESOURCE_ID string = resources.outputs.webAppResourceId
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
