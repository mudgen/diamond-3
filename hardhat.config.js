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
    chainId: 31337, // the default chain ID used by Hardhat Network's blockchain
    accounts: [
      { // owner
        privateKey: '2c73f309ac0547970ffefbe749c80a2bab7b17515e7d84f8bbb0857b65613c49',
        balance: '10000000000000000000000'
      },
      { // admin
        privateKey: '55219be66fd5ce0c8a16c6ad7cb6cf19797fd15cbcbe1957efc27efe92bf64c5',
        balance: '10000000000000000000000'
      }
    ]
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
