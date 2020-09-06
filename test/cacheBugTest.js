/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Diamond = artifacts.require('Diamond')
const DiamondFacet = artifacts.require('DiamondFacet')
const Test1Facet = artifacts.require('Test1Facet')

// The diamond example comes with 8 function selectors
// [cut, loupe, loupe, loupe, loupe, erc165, transferOwnership, owner]
// This bug manifests if you delete something from the final
// selector slot array, so we'll fill up a new slot with
// things, and have a fresh row to work with.
contract('Cache bug test', async accounts => {
  let test1Facet
  let diamondFacet
  let diamond
  let ownerSel

  const zeroAddress = '0x0000000000000000000000000000000000000000'

  // Selectors without 0x
  // web3.eth.abi.encodeFunctionSignature("test1Func2()").slice(2) etc
  const sel0 = '19e3b533' // fills up slot 1
  const sel1 = '0716c2ae' // fills up slot 1
  const sel2 = '11046047' // fills up slot 1
  const sel3 = 'cf3bbe18' // fills up slot 1
  const sel4 = '24c1d5a7' // fills up slot 1
  const sel5 = 'cbb835f6' // fills up slot 1
  const sel6 = 'cbb835f7' // fills up slot 1
  const sel7 = 'cbb835f8' // fills up slot 2
  const sel8 = 'cbb835f9' // fills up slot 2
  const sel9 = 'cbb835fa' // fills up slot 2
  const sel10 = 'cbb835fb' // fills up slot 2

  before(async () => {
    diamond = await Diamond.deployed()
    test1Facet = await Test1Facet.deployed()
    diamondFacet = new web3.eth.Contract(DiamondFacet.abi, diamond.address)
    web3.eth.defaultAccount = accounts[0]

    // Add functions
    let newFacetDescription = test1Facet.address + sel0 + sel1 + sel2 + sel3 + sel4 + sel5 + sel6 + sel7 + sel8 + sel9 + sel10
    await diamondFacet.methods.diamondCut([newFacetDescription], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })

    // Remove function selectors
    // Function selector for the owner function in slot 0
    ownerSel = '8da5cb5b'
    let removalDescription = zeroAddress + ownerSel + sel5 + sel10
    await diamondFacet.methods.diamondCut([removalDescription], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })
  })

  it('should not exhibit the cache bug', async () => {
    // Get the test1Facet's registered functions
    const selectors = await diamondFacet.methods.facetFunctionSelectors(test1Facet.address).call()

    // Check individual correctness
    assert.isTrue(selectors.includes('0x' + sel0), 'Does not contain sel0')
    assert.isTrue(selectors.includes('0x' + sel1), 'Does not contain sel1')
    assert.isTrue(selectors.includes('0x' + sel2), 'Does not contain sel2')
    assert.isTrue(selectors.includes('0x' + sel3), 'Does not contain sel3')
    assert.isTrue(selectors.includes('0x' + sel4), 'Does not contain sel4')
    assert.isTrue(selectors.includes('0x' + sel6), 'Does not contain sel6')
    assert.isTrue(selectors.includes('0x' + sel7), 'Does not contain sel7')
    assert.isTrue(selectors.includes('0x' + sel8), 'Does not contain sel8')
    assert.isTrue(selectors.includes('0x' + sel9), 'Does not contain sel9')

    assert.isFalse(selectors.includes('0x' + ownerSel), 'Contains ownerSel')
    assert.isFalse(selectors.includes('0x' + sel5), 'Contains sel5')
    assert.isFalse(selectors.includes('0x' + sel10), 'Contains sel10')
  })
})
