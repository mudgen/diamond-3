const DiamondExample = artifacts.require('DiamondExample')
const Test1Facet = artifacts.require('Test1Facet')
const Test2Facet = artifacts.require('Test2Facet')


module.exports = function(deployer) {
    // deployment steps
    // The constructor inside DiamondExample deploys DiamondFacet and DiamondLoupeFacet
    deployer.deploy(DiamondExample);
    deployer.deploy(Test1Facet);
    deployer.deploy(Test2Facet);

};

