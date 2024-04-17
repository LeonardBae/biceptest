param domainName string
param location string
//vnet
param devVnetName string
param devAppSubnetName string = '${domainName}-gai-dev-app-subnet'
param devPESubnetName string = '${domainName}-gai-dev-pe-subnet'
param devVnetAddressPrefix string
param devAppSubnetAddressPrefix string
param devPESubnetAddressPrefix string
//appservice
@description('Optional, defaults to S3. The SKU of the App Service Plan. Acceptable values are B3, S3 and P2v3.')
@allowed([
  'B2'
  'S3'
  'P2v3'
])
param devAppServicePlanSku string = 'B2'

resource devVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: devVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        devVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: devAppSubnetName
        properties: {
          addressPrefix: devAppSubnetAddressPrefix
        }
      }, {
        name: devPESubnetName
        properties: {
          addressPrefix: devPESubnetAddressPrefix
        }
      }
    ]
  }
}

