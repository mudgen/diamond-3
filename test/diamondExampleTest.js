const etherlime = require('etherlime-lib');

const DiamondExample = require('../build/DiamondExample.json');
const DiamondLoupe = require('../build/DiamondLoupe.json');
const DiamondFacet = require('../build/DiamondFacet.json');


describe('DiamondExampleTest', () => {
    let aliceAccount = accounts[0];
    let deployer;
    let diamondFacet;
    let diamondLoupe;

    before(async () => {
        deployer = new etherlime.EtherlimeGanacheDeployer(aliceAccount.secretKey);
        const diamondExample = await deployer.deploy(DiamondExample);
        //console.log(diamondExample);
        //diamondLoupe = deployer.wrapDeployedContract(DiamondLoupe, diamondExample.contractAddress);
        diamondFacet = deployer.wrapDeployedContract(DiamondFacet, diamondExample.contractAddress);
    });

    it('should get all the facets and functions of the contract', async () => {
        //console.log(diamondFacet.interface.events);
        let filter = diamondFacet.filters.DiamondCuts();
        console.log("testing");
       
        diamondFacet.contract.on(filter, (event) => {
            console.log(event);
        })
        

        //let functions = await diamondLoupe.facets();
        //console.log(functions[0]["facet"]);   
        // instead of showing the value of functions it shows a transaction
        //assert.equal(lime.name, 'newLime', '"newLime" was not created');
    });

});