targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@description('Name of the the Domain which is used to generate a short unique hash used in all resources.')
@minLength(1)
@maxLength(64)
param domainName string

@minLength(1)
@description('Primary location for all resources')
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

//rg
param hubRgName string = '${domainName}-gai-hub-rg'
param devRgName string = '${domainName}-gai-dev-rg'
param prdRgName string = '${domainName}-gai-prd-rg'

//hub infra param
param hubVnetName string = '${domainName}-gai-hub-vnet'
param hubVnetAddressPrefix string
param hubVpnSubnetAddressPrefix string
param hubAppGwSubnetAddressPrefix string
param vpnPublicIPName string = '${domainName}-gai-hub-vpn-pip'
param vpnGWName string = '${domainName}-gai-hub-vpngw'
param vpnSku string

//dev infra param
param devVnetName string = '${domainName}-gai-dev-vnet'
param devVnetAddressPrefix string
param devAppSubnetAddressPrefix string
param devPESubnetAddressPrefix string
param devJumpboxSubnetAddressPrefix string

//dev openai param
param devOpenAiName string = '${domainName}-gai-dev-openai'
param devOpenAiLocation string
param devOpenAiSkuName object = {
  name: 'S0'
}
param devAzureOpenAIAPIVersion string = '2023-12-01-preview'
param devChatGptDeploymentName string = '${domainName}-gai-dev-openai'
param devChatGptDeploymentCapacity int = 20
param devChatGptModelName string = 'gpt-3.5-turbo'
param devChatGptModelVersion string = '1106'
param devEmbeddingDeploymentName string = '${domainName}-gai-dev-openai'
param devEmbeddingDeploymentCapacity int = 30
param devEmbeddingModelName string = 'text-embedding-ada-002'

//prd openai param
param prdChatGptModelName string = 'gpt-4-32k'

resource hubRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubRgName
  location: location
}

resource devRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: devRgName
  location: location
}

resource prdRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: prdRgName
  location: location
}

module hubInfra 'hubinfra.bicep' = {
  name: 'hubinfra'
  scope: hubRg
  params: {
    location: location
    hubVnetName: hubVnetName
    hubVnetAddressPrefix: hubVnetAddressPrefix
    hubVpnSubnetAddressPrefix: hubVpnSubnetAddressPrefix
    hubAppGwSubnetAddressPrefix: hubAppGwSubnetAddressPrefix
    vpnPublicIPName: vpnPublicIPName
    vpnGWName: vpnGWName
    vpnSku: vpnSku
  }
}

module devOpenAi 'core/ai/devcognitivesvc.bicep' = {
  name: 'devOpenai'
  scope: devRg
  params: {
    devOpenAiName: devOpenAiName
    devOpenAiLocation: devOpenAiLocation
    devOpenAiSkuName: devOpenAiSkuName
    deployments: [
      {
        name: devChatGptDeploymentName
        model: {
          format: 'OpenAI'
          name: devChatGptModelName
          version: devChatGptModelVersion
        }
        sku: {
          name: 'Standard'
          capacity: devChatGptDeploymentCapacity
        }
      }
      {
        name: devEmbeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: devEmbeddingModelName
          version: '2'
        }
        capacity: devEmbeddingDeploymentCapacity
      }
    ]
  }
}
module devInfra 'devinfra.bicep' = {
  name: 'devinfra'
  scope: devRg
  params: {
    domainName: domainName
    location: location
    devVnetName: devVnetName
    devVnetAddressPrefix: devVnetAddressPrefix
    devAppSubnetAddressPrefix: devAppSubnetAddressPrefix
    devPESubnetAddressPrefix: devPESubnetAddressPrefix
    devJumpboxSubnetAddressPrefix: devJumpboxSubnetAddressPrefix
  }
  dependsOn: [
    devOpenAi
  ]
}

/*
resource devVnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'skcc-gai-dev-vnet'
  location: devRg.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        devVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'AppSubnet'
        properties: {
          addressPrefix: devAppSubnetAddressPrefix
        }
      },
      {
        name: 'PESubnet'
        properties: {
          addressPrefix: devPeSubnetAddressPrefix
        }
      },
      {
        name: 'JumpboxSubnet'
        properties: {
          addressPrefix: devJumpboxSubnetAddressPrefix
        }
      }
    ]
  }
  dependsOn: [
    devRg
  ]
}

resource prdVnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'skcc-gai-prd-vnet'
  location: prdRg.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        prdVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'AppSubnet'
        properties: {
          addressPrefix: prdAppSubnetAddressPrefix
        }
      },
      {
        name: 'PESubnet'
        properties: {
          addressPrefix: prdPeSubnetAddressPrefix
        }
      }
    ]
  }
  dependsOn: [
    prdRg
  ]
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: devRg.location
  properties: {
    sku: {
      family: skuFamily
      name: skuName
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: '<your-object-id>'
        permissions: {
          secrets: [
            'get',
            'list',
            'set'
          ]
        }
      }
    ]
  }
  dependsOn: [
    devRg
  ]
}

resource openAi 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/${openAiName}'
  properties: {
    value: '<your-secret-value>'
  }
  dependsOn: [
    keyVault
  ]
}

resource search 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/${searchName}'
  properties: {
    value: '<your-secret-value>'
  }
  dependsOn: [
    keyVault
  ]
}

resource cosmosDb 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/${cosmosDbName}'
  properties: {
    value: '<your-secret-value>'
  }
  dependsOn: [
    keyVault
  ]
}

resource storageAccount 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/${storageAccountName}'
  properties: {
    value: '<your-secret-value>'
  }
  dependsOn: [
    keyVault
  ]
}

resource docIntelli 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/${docIntelliName}'
  properties: {
    value: '<your-secret-value>'
  }
  dependsOn: [
    keyVault
  ]
}

resource cognitive 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/${cognitiveName}'
  properties: {
    value: '<your-secret-value>'
  }
  dependsOn: [
    keyVault
  ]
}

resource bot 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/${botName}'
  properties: {
    value: '<your-secret-value>'
  }
  dependsOn: [
    keyVault
  ]
}

resource jumpboxVm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: jumpboxVmName
  location: devRg.location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: jumpboxVmName
      adminUsername: 'adminUser'
      adminPassword: 'yourPassword'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: '/subscriptions/<subscription-id>/resourceGroups/skcc-gai-dev-rg/providers/Microsoft.Network/networkInterfaces/<your-nic-id>'
        }
      ]
    }
  }
  dependsOn: [
    devRg
  ]
}
*/
