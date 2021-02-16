require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-truffle5')
require('hardhat-contract-sizer')
require('solidity-coverage')

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  hardhat: {
    blockGasLimit: 10000000, // default: 9,500,000 gas limit
    live: false,
    saveDeployments: false,
    chainId: 31337 // the default chain ID used by Hardhat Network's blockchain
  },
  solidity: {
    version: '0.8.1',
    settings: {
      optimizer: {
        enabled: false,
        runs: 200
      }
    }
  },
  namedAccounts: {
    deployer: {
      default: 0
    },
    admin: {
      default: 1
    }
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false
  }
}
