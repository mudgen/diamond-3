const etherlime = require('etherlime-lib');

const Test1Facet = require('../build/Test1Facet.json');
const DiamondExample = require('../build/DiamondExample.json');
const DiamondLoupeFacet = require('../build/DiamondLoupeFacet.json');
const DiamondFacet = require('../build/DiamondFacet.json');


describe('Cache bug', () => {
    let aliceAccount = accounts[0];
    let deployer;
    let test1Facet;
    let test2Facet;
    let diamondFacet;
    let diamondLoupeFacet;
    let diamondExample;

    const zeroAddress = "0x0000000000000000000000000000000000000000";

    // Selectors without 0x
    // web3.eth.abi.encodeFunctionSignature("test1Func2()").slice(2) etc
    const sel0 = '19e3b533';
    const sel1 = '0716c2ae';
    const sel2 = '11046047';
    const sel3 = 'cf3bbe18';

    before(async () => {
        deployer = new etherlime.EtherlimeGanacheDeployer(aliceAccount.secretKey);
        diamondExample = await deployer.deploy(DiamondExample);
        test1Facet = await deployer.deploy(Test1Facet);
        diamondLoupeFacet = deployer.wrapDeployedContract(DiamondLoupeFacet, diamondExample.contractAddress);
        diamondFacet = deployer.wrapDeployedContract(DiamondFacet, diamondExample.contractAddress);

        // Add facet
        let newFacetDescription = test1Facet.contractAddress + sel0 + sel1 + sel2 + sel3;
        await diamondFacet.diamondCut([newFacetDescription]);

        // Remove facet
        let removalDescription = zeroAddress + sel1;
        await diamondFacet.diamondCut([removalDescription]);
    });
    
    // If the bug is present, this should leave the last slot in cache as
    // [ sel0 sel3 sel2 ] (sel3 off the edge)
    // but not write it back, so the storage should still have
    // [ sel0 sel1 sel2 ] (sel3 off the edge)

    it("should not exhibit the cache bug", async () => {
        // Get the test1Facet's registered functions
        let selectors = await diamondLoupeFacet.facetFunctionSelectors(test1Facet.contractAddress);
        console.log(selectors);
        console.log([sel0, sel1, sel2, sel3].join(" "));

        // Short-circuit test for our specific bug
        assert.isFalse((!selectors.includes(sel3)) && selectors.includes(sel1), "Exhibits the cache bug");

        // Check individual correctness
        assert.isTrue(selectors.includes(sel0), "Does not contain sel0");
        assert.isTrue(selectors.includes(sel2), "Does not contain sel2");
        assert.isTrue(selectors.includes(sel3), "Does not contain sel3");

        assert.isFalse(selectors.includes(sel1), "Contains sel1");
    });
});