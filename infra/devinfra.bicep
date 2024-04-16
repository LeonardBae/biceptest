param domainName string
param location string
//vnet
param devVnetName string
param devAppSubnetName string = '${domainName}-gai-dev-app-subnet'
param devPESubnetName string = '${domainName}-gai-dev-pe-subnet'
param devVnetAddressPrefix string
param devAppSubnetAddressPrefix string
param devPESubnetAddressPrefix string

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
