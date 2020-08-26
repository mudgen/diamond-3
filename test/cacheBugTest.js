/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const DiamondExample = artifacts.require('DiamondExample')
const DiamondLoupeFacet = artifacts.require('DiamondLoupeFacet')
const DiamondFacet = artifacts.require('DiamondFacet')
const Test1Facet = artifacts.require('Test1Facet')

// The standard diamond example comes with 6 full slots.
// [cut, loupe, loupe, loupe, loupe, erc165]
// This bug manifests if you delete something from the final
// selector slot array, so we'll fill up this slot with 2 more
// things, and have a fresh row to work with.
contract('Cache bug test', async accounts => {
  let test1Facet
  let diamondFacet
  let diamondLoupeFacet
  let diamondExample

  const zeroAddress = '0x0000000000000000000000000000000000000000'

  // Selectors without 0x
  // web3.eth.abi.encodeFunctionSignature("test1Func2()").slice(2) etc
  const sel0 = '19e3b533' // fills up slot 0
  const sel1 = '0716c2ae' // fills up slot 0
  const sel2 = '11046047' // all others into slot 1
  const sel3 = 'cf3bbe18'
  const sel4 = '24c1d5a7'
  const sel5 = 'cbb835f6'

  before(async () => {
    diamondExample = await DiamondExample.deployed()
    test1Facet = await Test1Facet.deployed()
    diamondLoupeFacet = new web3.eth.Contract(DiamondLoupeFacet.abi, diamondExample.address)
    diamondFacet = new web3.eth.Contract(DiamondFacet.abi, diamondExample.address)
    web3.eth.defaultAccount = accounts[0]

    // Add functions
    let newFacetDescription = test1Facet.address + sel0 + sel1 + sel2 + sel3 + sel4 + sel5
    await diamondFacet.methods.diamondCut([newFacetDescription], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })

    // Remove function
    let removalDescription = zeroAddress + sel3
    await diamondFacet.methods.diamondCut([removalDescription], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })
  })

  // If the bug is present, this should leave the last slot in cache as
  // [ sel2 sel5 sel4 ] (sel5 off the edge)
  // but not write it back, so the storage should still have
  // [ sel2 sel3 sel4 ] (sel5 off the edge)

  it('should not exhibit the cache bug', async () => {
    // Get the test1Facet's registered functions
    const selectors = await diamondLoupeFacet.methods.facetFunctionSelectors(test1Facet.address).call()
    // console.log([sel0, sel1, sel2, sel3, sel4, sel5].join(" "));

    // Check individual correctness
    assert.isTrue(selectors.includes(sel0), 'Does not contain sel0')
    assert.isTrue(selectors.includes(sel1), 'Does not contain sel1')
    assert.isTrue(selectors.includes(sel2), 'Does not contain sel2')
    assert.isTrue(selectors.includes(sel4), 'Does not contain sel4')
    assert.isTrue(selectors.includes(sel5), 'Does not contain sel5')

    assert.isFalse(selectors.includes(sel3), 'Contains sel3')
  })
})
