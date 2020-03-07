const etherlime = require('etherlime-lib');
const ethers = require('ethers');
const utils = ethers.utils;
const DiamondExample = require('../build/DiamondExample.json');
const DiamondLoupeFacet = require('../build/DiamondLoupeFacet.json');
const DiamondFacet = require('../build/DiamondFacet.json');
const TestFacet = require('../build/TestFacet.json');


describe('DiamondExampleTest', () => {
    let aliceAccount = accounts[0];
    let deployer;
    let testFacet;
    let diamondFacet;
    let diamondLoupeFacet;

    let result;
    let addresses;

    before(async () => {
        deployer = new etherlime.EtherlimeGanacheDeployer(aliceAccount.secretKey);
        const diamondExample = await deployer.deploy(DiamondExample);
        testFacet = await deployer.deploy(TestFacet);

        //console.log(diamondExample);
        diamondLoupeFacet = deployer.wrapDeployedContract(DiamondLoupeFacet, diamondExample.contractAddress);
        diamondFacet = deployer.wrapDeployedContract(DiamondFacet, diamondExample.contractAddress);
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
        let values = Array.from(new Set(Object.values(testFacet.interface.functions)));
        //console.log(values);
        let selectors = values.reduce((acc, val) => {
            return acc + val.sighash.slice(2);
        }, "");
        console.log(selectors);
        result = await diamondFacet.diamondCut([testFacet.contractAddress + selectors]);
        console.log(result);

        

    });


});