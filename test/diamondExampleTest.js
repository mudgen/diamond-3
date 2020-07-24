const etherlime = require('etherlime-lib');
const ethers = require('ethers');
const utils = ethers.utils;
const DiamondExample = require('../build/DiamondExample.json');
const DiamondLoupeFacet = require('../build/DiamondLoupeFacet.json');
const DiamondFacet = require('../build/DiamondFacet.json');
const Test1Facet = require('../build/Test1Facet.json');
const Test2Facet = require('../build/Test2Facet.json');


function getSelectors(contract) {
    let values = Array.from(new Set(Object.values(contract.interface.functions)));        
    let selectors = values.reduce((acc, val) => {
        return acc + val.sighash.slice(2);
    }, ""); 
    return selectors;
}

describe('DiamondExampleTest', () => {
    let aliceAccount = accounts[0];
    let deployer;
    let test1Facet;
    let test2Facet;
    let diamondFacet;
    let diamondLoupeFacet;
    let diamondExample;

    let result;
    let addresses;

    before(async () => {
        deployer = new etherlime.EtherlimeGanacheDeployer(aliceAccount.secretKey);
        diamondExample = await deployer.deploy(DiamondExample);        
        diamondLoupeFacet = deployer.wrapDeployedContract(DiamondLoupeFacet, diamondExample.contractAddress);
        diamondFacet = deployer.wrapDeployedContract(DiamondFacet, diamondExample.contractAddress);
        test1Facet = await deployer.deploy(Test1Facet);
        test2Facet = await deployer.deploy(Test2Facet);
    });    
    
    it('should have three facets', async () => {
        result = await diamondLoupeFacet.facetAddresses();
        addresses = result.slice(2).match(/.{40}/g).map(address => utils.getAddress(address));
        assert.equal(addresses.length, 3);

    });

    it('facets should have the right function selectors', async () => {
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0]);        
        assert.equal(result, "0x99f5f52e");
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1]);
        assert.equal(result, "0xadfca15e7a0ed627cdffacc652ef6b2c");
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2]);
        assert.equal(result, "0x01ffc9a7");
    });

    it('selectors should be associated to facets correctly', async () => {
        assert.equal(addresses[0], await diamondLoupeFacet.facetAddress("0x99f5f52e"));
        assert.equal(addresses[1], await diamondLoupeFacet.facetAddress("0xcdffacc6"));
        assert.equal(addresses[2], await diamondLoupeFacet.facetAddress("0x01ffc9a7"));
    });

    it('should get all the facets and function selectors of the diamond', async () => {
        result = await diamondLoupeFacet.facets();

        assert.equal(addresses[0], utils.getAddress(result[0].slice(0,42)));
        assert.equal(result[0].slice(42), "99f5f52e");

        assert.equal(addresses[1], utils.getAddress(result[1].slice(0,42)));
        assert.equal(result[1].slice(42), "adfca15e7a0ed627cdffacc652ef6b2c");

        assert.equal(addresses[2], utils.getAddress(result[2].slice(0,42)));
        assert.equal(result[2].slice(42), "01ffc9a7");

        assert.equal(result.length, 3);
    });

    it('should add test1 functions', async () => {        
        let selectors = getSelectors(test1Facet);
        addresses.push(test1Facet.contractAddress);            
        result = await diamondFacet.diamondCut([test1Facet.contractAddress + selectors]);
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[3]);        
        let frontSelector = selectors.slice(-8);
        selectors = "0x"+frontSelector + selectors.slice(0,-8);
        assert.equal(result, selectors);
    });

    it('should add test2 functions', async () => {        
        let selectors = getSelectors(test2Facet);
        addresses.push(test2Facet.contractAddress);            
        result = await diamondFacet.diamondCut([test2Facet.contractAddress + selectors]);
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[4]);        
        assert.equal(result, "0x"+selectors);

    });

    it('should remove some test2 functions', async () => {        
        let selectors = getSelectors(test2Facet);
        removeSelectors = selectors.slice(0,8) + selectors.slice(32,48) + selectors.slice(-16);        
        result = await diamondFacet.diamondCut([ethers.constants.AddressZero + removeSelectors]);
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[4]);        
        selectors = selectors.slice(-40,-32) + selectors.slice(8,32) + selectors.slice(-32,-16) + selectors.slice(48,-40);
        assert.equal(result, "0x"+selectors);
    });


    it('should remove some test1 functions', async () => {        
        let selectors = getSelectors(test1Facet);
        let frontSelector = selectors.slice(-8);
        selectors = frontSelector + selectors.slice(0,-8);

        removeSelectors = selectors.slice(8,16)  + selectors.slice(64,80);        
        result = await diamondFacet.diamondCut([ethers.constants.AddressZero + removeSelectors]);
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[3]);        
        selectors = selectors.slice(0,8) + selectors.slice(16,64) + selectors.slice(80);
        assert.equal(result, "0x"+selectors);
    });


});