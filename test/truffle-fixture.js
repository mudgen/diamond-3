/* eslint-disable prefer-const */
/* global artifacts */
const Diamond = artifacts.require('Diamond')
const DiamondCutFacet = artifacts.require('DiamondCutFacet')
const DiamondLoupeFacet = artifacts.require('DiamondLoupeFacet')
const OwnershipFacet = artifacts.require('OwnershipFacet')
const Test1Facet = artifacts.require('Test1Facet')
const Test2Facet = artifacts.require('Test2Facet')

const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2
}

function getSelectors (contract) {
  const selectors = contract.abi.reduce((acc, val) => {
    if (val.type === 'function') {
      acc.push(val.signature)
      return acc
    } else {
      return acc
    }
  }, [])
  return selectors
}

// https://hardhat.org/guides/truffle-migration.html#migrations-and-hardhat-truffle-fixtures
module.exports = async () => {
  // eslint-disable-next-line no-undef
  const accounts = await ethers.getSigners()
  const admin = accounts[1]

  const cutFacet = await DiamondCutFacet.new()
  DiamondCutFacet.setAsDeployed(cutFacet)
  const loupeFacet = await DiamondLoupeFacet.new()
  DiamondLoupeFacet.setAsDeployed(loupeFacet)

  const diamondCut = [
    [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
    [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
    [OwnershipFacet.address, FacetCutAction.Add, getSelectors(OwnershipFacet)]
  ]

  const diamond = await Diamond.new(diamondCut, admin)
  Diamond.setAsDeployed(diamond)

  const test1Facet = await Test1Facet.new()
  Test1Facet.setAsDeployed(test1Facet)
  const test2Facet = await Test2Facet.new()
  Test2Facet.setAsDeployed(test2Facet)
}
