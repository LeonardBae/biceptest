param domainName string
param location string
//vnet
param devVnetName string
param devAppSubnetName string = '${domainName}-gai-dev-app-subnet'
param devPESubnetName string = '${domainName}-gai-dev-pe-subnet'
param devJumpboxSubnetName string = '${domainName}-gai-dev-pe-subnet'
param devVnetAddressPrefix string
param devAppSubnetAddressPrefix string
param devPESubnetAddressPrefix string
param devJumpboxSubnetAddressPrefix string
//appservice
@description('Optional, defaults to S3. The SKU of the App Service Plan. Acceptable values are B3, S3 and P2v3.')
@allowed([
  'B1','B2','B3','S1','S2','S3','S3','P1v3','P2v3','P3v3'
])
param devAppServicePlanSku string = 'B2'
param appServicePlanName string = '${domainName}-gai-dev-asp'
param devWebAppName string = '${domainName}-gai-dev-webapp'

resource devAppServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: devAppServicePlanSku
  }
  kind: 'linux'
}

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
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }, {
        name: devPESubnetName
        properties: {
          addressPrefix: devPESubnetAddressPrefix
        }
      }, {
        name: devJumpboxSubnetName
        properties: {
          addressPrefix: devJumpboxSubnetAddressPrefix
        }
      }
    ]
  }
}

resource devWebApp 'Microsoft.Web/sites@2022-09-01' = {
  name: devWebAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: devAppServicePlan.id
    virtualNetworkSubnetId: devVnet.properties.subnets[0].id
    httpsOnly: true
    vnetRouteAllEnabled: false
  }
}
