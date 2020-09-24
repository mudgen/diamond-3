/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Diamond = artifacts.require('Diamond')
const DiamondCutFacet = artifacts.require('DiamondCutFacet')
const DiamondLoupeFacet = artifacts.require('DiamondLoupeFacet')
const Test1Facet = artifacts.require('Test1Facet')

const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2
}

// The diamond example comes with 8 function selectors
// [cut, loupe, loupe, loupe, loupe, erc165, transferOwnership, owner]
// This bug manifests if you delete something from the final
// selector slot array, so we'll fill up a new slot with
// things, and have a fresh row to work with.
contract('Cache bug test', async accounts => {
  let test1Facet
  let diamondCutFacet
  let diamondLoupeFacet
  let diamond
  const ownerSel = '0x8da5cb5b'
  const zeroAddress = '0x0000000000000000000000000000000000000000'
  // Selectors without 0x
  // web3.eth.abi.encodeFunctionSignature("test1Func2()").slice(2) etc
  const sel0 = '0x19e3b533' // fills up slot 1
  const sel1 = '0x0716c2ae' // fills up slot 1
  const sel2 = '0x11046047' // fills up slot 1
  const sel3 = '0xcf3bbe18' // fills up slot 1
  const sel4 = '0x24c1d5a7' // fills up slot 1
  const sel5 = '0xcbb835f6' // fills up slot 1
  const sel6 = '0xcbb835f7' // fills up slot 1
  const sel7 = '0xcbb835f8' // fills up slot 2
  const sel8 = '0xcbb835f9' // fills up slot 2
  const sel9 = '0xcbb835fa' // fills up slot 2
  const sel10 = '0xcbb835fb' // fills up slot 2
  let selectors = [
    sel0,
    sel1,
    sel2,
    sel3,
    sel4,
    sel5,
    sel6,
    sel7,
    sel8,
    sel9,
    sel10
  ]

  before(async () => {
    diamond = await Diamond.deployed()
    test1Facet = await Test1Facet.deployed()
    diamondCutFacet = new web3.eth.Contract(DiamondCutFacet.abi, diamond.address)
    diamondLoupeFacet = new web3.eth.Contract(DiamondLoupeFacet.abi, diamond.address)
    web3.eth.defaultAccount = accounts[0]

    // Add functions
    await diamondCutFacet.methods.diamondCut([[test1Facet.address, FacetCutAction.Add, selectors]], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })

    // Remove function selectors
    // Function selector for the owner function in slot 0
    selectors = [
      ownerSel, // owner selector
      sel5,
      sel10
    ]
    await diamondCutFacet.methods.diamondCut([[zeroAddress, FacetCutAction.Remove, selectors]], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })
  })

  it('should not exhibit the cache bug', async () => {
    // Get the test1Facet's registered functions
    selectors = await diamondLoupeFacet.methods.facetFunctionSelectors(test1Facet.address).call()

    // Check individual correctness
    assert.isTrue(selectors.includes(sel0), 'Does not contain sel0')
    assert.isTrue(selectors.includes(sel1), 'Does not contain sel1')
    assert.isTrue(selectors.includes(sel2), 'Does not contain sel2')
    assert.isTrue(selectors.includes(sel3), 'Does not contain sel3')
    assert.isTrue(selectors.includes(sel4), 'Does not contain sel4')
    assert.isTrue(selectors.includes(sel6), 'Does not contain sel6')
    assert.isTrue(selectors.includes(sel7), 'Does not contain sel7')
    assert.isTrue(selectors.includes(sel8), 'Does not contain sel8')
    assert.isTrue(selectors.includes(sel9), 'Does not contain sel9')

    assert.isFalse(selectors.includes(ownerSel), 'Contains ownerSel')
    assert.isFalse(selectors.includes(sel10), 'Contains sel10')
    assert.isFalse(selectors.includes(sel5), 'Contains sel5')
  })
})
