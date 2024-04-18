metadata description = 'Creates an Azure Cognitive Services instance.'
param devOpenAiName string
param devOpenAiLocation string
@description('The custom subdomain name used to access the API. Defaults to the value of the name parameter.')
param customSubDomainName string = devOpenAiName
param deployments array = []
param publicNetworkAccess string = 'Disabled'
param devOpenAiSkuName object

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: devOpenAiName
  location: devOpenAiLocation
  kind: 'OpenAI'
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
  }
  sku: devOpenAiSkuName
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: account
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
  }
  sku: contains(deployment, 'sku') ? deployment.sku : {
    name: 'Standard'
    capacity: 20
  }
}]

output endpoint string = account.properties.endpoint
output id string = account.id
output name string = account.name
var keys = account.listKeys()
output key string = keys.key1
