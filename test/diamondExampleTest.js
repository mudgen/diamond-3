const etherlime = require('etherlime-lib');

const DiamondExample = require('../build/DiamondExample.json');
const DiamondLoupeFacet = require('../build/DiamondLoupeFacet.json');
const DiamondFacet = require('../build/DiamondFacet.json');


describe('DiamondExampleTest', () => {
    let aliceAccount = accounts[0];
    let deployer;
    let diamondFacet;
    let diamondLoupeFacet;

    before(async () => {
        deployer = new etherlime.EtherlimeGanacheDeployer(aliceAccount.secretKey);
        const diamondExample = await deployer.deploy(DiamondExample);
        //console.log(diamondExample);
        diamondLoupeFacet = deployer.wrapDeployedContract(DiamondLoupeFacet, diamondExample.contractAddress);
        //diamondFacet = deployer.wrapDeployedContract(DiamondFacet, diamondExample.contractAddress);
    });

    it('should get all the facets and functions of the contract', async () => {
        //console.log(diamondFacet.interface.events);
        //let filter = diamondFacet.filters.DiamondCuts();
        //console.log("testing");
       
        //diamondFacet.contract.on(filter, (event) => {
        //    console.log(event);
        //})
        
        //console.log("got here");
        //let result = await diamondLoupeFacet.facets();
        let result = await diamondLoupeFacet.facetAddresses();
        let addresses = result.slice(2).match(/.{40}/g);
        //console.log(addresses);
        //result = await diamondLoupeFacet.getArrayLengths();
        result = await diamondLoupeFacet.getArray();
        console.log(result);
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0]);
        console.log(result);

        result = await diamondLoupeFacet.facets();
        console.log(result);

        result = await diamondLoupeFacet.facetAddress("0x7a0ed627");
        console.log("address:" + result);
        //console.log(functions[0]["facet"]);   
        // instead of showing the value of functions it shows a transaction
        //assert.equal(lime.name, 'newLime', '"newLime" was not created');
    });

});