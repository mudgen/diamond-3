const etherlime = require('etherlime-lib');

const DiamondExample = require('../build/DiamondExample.json');
const DiamondFacet = require('../build/DiamondFacet.json');


describe('DiamondExampleTest', () => {
    let aliceAccount = accounts[0];
    let deployer;
    let diamondFacet;

    before(async () => {
        deployer = new etherlime.EtherlimeGanacheDeployer(aliceAccount.secretKey);
        const diamondExample = await deployer.deploy(DiamondExample);
        diamondFacet = deployer.wrapDeployedContract(DiamondFacet, diamondExample.contractAddress);
        //console.log(diamondExample.contractAddress);
        
        //diamondFacet = await etherlime.ContractAt(DiamondFacet, diamondExample.contractAddress);        
    });

    it('should get all the facets and functions of the contract', async () => {
        //console.log(await diamondFacet.functions.totalFunctions());
        let functions = await diamondFacet.totalFunctions();
        console.log(functions);   
        // instead of showing the value of functions it shows a transaction
        //assert.equal(lime.name, 'newLime', '"newLime" was not created');
    });

});