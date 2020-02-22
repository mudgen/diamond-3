const etherlime = require('etherlime-lib');
const DiamondExample = require('../build/DiamondExample.json');


const deploy = async (network, secret, etherscanApiKey) => {

	const deployer = new etherlime.EtherlimeGanacheDeployer();
	const result = await deployer.deploy(DiamondExample);

};

module.exports = {
	deploy
};