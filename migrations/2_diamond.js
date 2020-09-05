const Diamond = artifacts.require('Diamond')
const Test1Facet = artifacts.require('Test1Facet')
const Test2Facet = artifacts.require('Test2Facet')

module.exports = function (deployer, network, accounts) {
  // deployment steps
  // The constructor inside Diamond deploys DiamondFacet
  deployer.deploy(Diamond, accounts[0])
  deployer.deploy(Test1Facet)
  deployer.deploy(Test2Facet)
}
