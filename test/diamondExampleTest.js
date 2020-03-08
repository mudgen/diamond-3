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
    let diamondFacet;
    let diamondLoupeFacet;
    let diamondExample;

    let result;
    let addresses;

    before(async () => {
        deployer = new etherlime.EtherlimeGanacheDeployer(aliceAccount.secretKey);
        diamondExample = await deployer.deploy(DiamondExample);
        test1Facet = await deployer.deploy(Test1Facet);

        //console.log(diamondExample);
        diamondLoupeFacet = deployer.wrapDeployedContract(DiamondLoupeFacet, diamondExample.contractAddress);
        diamondFacet = deployer.wrapDeployedContract(DiamondFacet, diamondExample.contractAddress);
    });
    //function splitAddresses()
    
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

    it('should get all the facets and function selectors of the contract', async () => {
        result = await diamondLoupeFacet.facets();

        assert.equal(addresses[0], utils.getAddress(result[0].slice(0,42)));
        assert.equal(result[0].slice(42), "99f5f52e");

        assert.equal(addresses[1], utils.getAddress(result[1].slice(0,42)));
        assert.equal(result[1].slice(42), "adfca15e7a0ed627cdffacc652ef6b2c");

        assert.equal(addresses[2], utils.getAddress(result[2].slice(0,42)));
        assert.equal(result[2].slice(42), "01ffc9a7");

        assert.equal(result.length, 3);
    });

    it('should add test functions', async () => {        
        let selectors = getSelectors(test1Facet);
        addresses.push(test1Facet.contractAddress);            
        result = await diamondFacet.diamondCut([test1Facet.contractAddress + selectors]);
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[3]);        
        let frontSelector = selectors.slice(-8);
        selectors = "0x"+frontSelector + selectors.slice(0,-8);
                
        /*
        result = await diamondExample.getArrayLengths()
        console.log("array length:"+ result);
        result = await diamondExample.getArray();
        console.log(result);
        */
        assert.equal(result, selectors);
        // testing that the new function selectors exist
        //assert.equal(result, "0x561f5f89087523609a5fb5a8652bf6a79805335e041f8e348b4f47fd732c788f5fa566265aa2e332f55c1f8163d11d697be03193c73ba61d106bac4f23232be8fd06f19be868fb8f5dc36e5dd89d0d2101ffc9a7");        
    });




});