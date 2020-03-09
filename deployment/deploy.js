const etherlime = require('etherlime-lib');
const DiamondExample = require('../build/DiamondExample.json');
const ethers = require('ethers');

const deploy = async (networks, secrets, etherscanApiKeys) => {
	
	const deployer = new etherlime.EtherlimeGanacheDeployer();
	const result = await deployer.deploy(DiamondExample);
	
};

module.exports = {
	deploy
};