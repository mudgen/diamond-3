const etherlime = require('etherlime-lib');
const Diamond = require('../build/Diamond.json');
const ethers = require('ethers');

const deploy = async (networks, secrets, etherscanApiKeys) => {
	
	const deployer = new etherlime.EtherlimeGanacheDeployer();
	const result = await deployer.deploy(Diamond, "0x0000000000000000000000000000000000000000");
	
};

module.exports = {
	deploy
};