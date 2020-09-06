/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Diamond = artifacts.require('Diamond')
const DiamondFacet = artifacts.require('DiamondFacet')
const Test1Facet = artifacts.require('Test1Facet')
const Test2Facet = artifacts.require('Test2Facet')

contract('DiamondTest', async accounts => {
  let diamondFacet
  let diamond
  let test1Facet
  let test2Facet

  let removeSelectors
  let result
  let addresses

  let zeroAddress = '0x0000000000000000000000000000000000000000'

  before(async () => {
    test1Facet = await Test1Facet.deployed()
    test2Facet = await Test2Facet.deployed()
    diamond = await Diamond.deployed()
    diamondFacet = new web3.eth.Contract(DiamondFacet.abi, diamond.address)

    web3.eth.defaultAccount = accounts[0]
  })

  it('should have two facets -- call to facetAddresses function', async () => {
    addresses = await diamondFacet.methods.facetAddresses().call()
    assert.equal(addresses.length, 2)
  })

  it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
    result = await diamondFacet.methods.facetFunctionSelectors(addresses[0]).call()
    assert.deepEqual(result, [
      '0x7c696fea',
      '0xadfca15e',
      '0x7a0ed627',
      '0xcdffacc6',
      '0x52ef6b2c',
      '0x01ffc9a7'
    ])
    result = await diamondFacet.methods.facetFunctionSelectors(addresses[1]).call()
    assert.deepEqual(result, [
      '0xf2fde38b',
      '0x8da5cb5b'
    ])
  })

  it('selectors should be associated to facets correctly -- multiple calls to facetAddress function', async () => {
    assert.equal(addresses[0], await diamondFacet.methods.facetAddress('0x7c696fea').call())
    assert.equal(addresses[0], await diamondFacet.methods.facetAddress('0xcdffacc6').call())
    assert.equal(addresses[0], await diamondFacet.methods.facetAddress('0x01ffc9a7').call())
    assert.equal(addresses[1], await diamondFacet.methods.facetAddress('0xf2fde38b').call())
  })

  it('should get all the facets and function selectors of the diamond -- call to facets function', async () => {
    result = await diamondFacet.methods.facets().call()
    assert.equal(result[0].facetAddress, addresses[0])
    assert.deepEqual(result[0].functionSelectors, [
      '0x7c696fea',
      '0xadfca15e',
      '0x7a0ed627',
      '0xcdffacc6',
      '0x52ef6b2c',
      '0x01ffc9a7'
    ])
    assert.equal(result[1].facetAddress, addresses[1])
    assert.deepEqual(result[1].functionSelectors, [
      '0xf2fde38b',
      '0x8da5cb5b'
    ])
    assert.equal(result.length, 2)
  })

  function getSelectors (contract) {
    const selectors = contract.abi.reduce((acc, val) => {
      if (val.type === 'function') {
        return acc + val.signature.slice(2)
      } else {
        return acc
      }
    }, '')
    return selectors
  }

  function reduceSelectorsResult (result) {
    result = result.reduce((acc = '', value) => {
      return acc + value.slice(2)
    })
    return result
  }

  it('should add test1 functions', async () => {
    let selectors = getSelectors(test1Facet)
    addresses.push(test1Facet.address)
    await diamondFacet.methods.diamondCut([test1Facet.address + selectors], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })
    result = await diamondFacet.methods.facetFunctionSelectors(addresses[2]).call()
    const frontSelector = selectors.slice(-8)
    selectors = '0x' + frontSelector + selectors.slice(0, -8)
    result = reduceSelectorsResult(result)
    assert.equal(result, selectors)
  })

  it('should add test2 functions', async () => {
    const selectors = getSelectors(test2Facet)
    addresses.push(test2Facet.address)
    await diamondFacet.methods.diamondCut([test2Facet.address + selectors], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })
    result = await diamondFacet.methods.facetFunctionSelectors(addresses[3]).call()
    result = reduceSelectorsResult(result)
    assert.equal(result, '0x' + selectors)
  })

  it('should remove some test2 functions', async () => {
    let selectors = getSelectors(test2Facet)
    removeSelectors = selectors.slice(0, 8) + selectors.slice(32, 48) + selectors.slice(-16)
    result = await diamondFacet.methods.diamondCut([zeroAddress + removeSelectors], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })
    result = await diamondFacet.methods.facetFunctionSelectors(addresses[3]).call()
    selectors = selectors.slice(-40, -32) + selectors.slice(8, 32) + selectors.slice(-32, -16) + selectors.slice(48, -40)
    result = reduceSelectorsResult(result)
    assert.equal(result, '0x' + selectors)
  })

  it('should remove some test1 functions', async () => {
    let selectors = getSelectors(test1Facet)
    const frontSelector = selectors.slice(-8)
    selectors = frontSelector + selectors.slice(0, -8)
    removeSelectors = selectors.slice(8, 16) + selectors.slice(64, 80)
    result = await diamondFacet.methods.diamondCut([zeroAddress + removeSelectors], zeroAddress, '0x').send({ from: web3.eth.defaultAccount, gas: 1000000 })
    result = await diamondFacet.methods.facetFunctionSelectors(addresses[2]).call()
    selectors = selectors.slice(0, 8) + selectors.slice(16, 64) + selectors.slice(80)
    result = reduceSelectorsResult(result)
    assert.equal(result, '0x' + selectors)
  })
})
