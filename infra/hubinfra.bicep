param location string
//vnet
param hubVnetName string
param hubVpnSubnetName string = 'GatewaySubnet'
param hubAppgwSubnetName string = 'AppGWSubnet'
param hubVnetAddressPrefix string
param hubVpnSubnetAddressPrefix string
param hubAppGwSubnetAddressPrefix string
//vpn 
param vpnPublicIPName string
param gatewayType string = 'Vpn'
param vpnType string = 'RouteBased'
param vpnGWName string
param enableBGP bool = false
param vpnSku string
//localngw

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: hubVpnSubnetName
        properties: {
          addressPrefix: hubVpnSubnetAddressPrefix
        }
      }, {
        name: hubAppgwSubnetName
        properties: {
          addressPrefix: hubAppGwSubnetAddressPrefix
        }
      }
    ]
  }
}

resource vpnPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: vpnPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGW 'Microsoft.Network/virtualNetworkGateways@2023-09-01' = {
  name: vpnGWName
  location: location
  properties: {
    gatewayType: gatewayType
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', hubVnetName, hubVpnSubnetName)
          }
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIPAddresses', vpnPublicIPName)
          }
        }
      }
    ]
    vpnType: vpnType
    enableBgp: enableBGP
    sku: {
      name: vpnSku
      tier: vpnSku
    }
  }
  dependsOn: [
    vpnPublicIP
  ]
}


