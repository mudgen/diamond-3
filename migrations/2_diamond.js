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

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Test1Facet)
  deployer.deploy(Test2Facet)

  deployer.deploy(DiamondCutFacet)
  deployer.deploy(DiamondLoupeFacet)
  deployer.deploy(OwnershipFacet).then(() => {
    const diamondCut = [
      [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
      [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
      [OwnershipFacet.address, FacetCutAction.Add, getSelectors(OwnershipFacet)]
    ]
    return deployer.deploy(Diamond, diamondCut, [accounts[0]])
  })
}
