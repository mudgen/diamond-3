# Diamond Standard Reference Implementation
This is the gas-optimized reference implementation for [EIP-2535 Diamond Standard](https://github.com/ethereum/EIPs/issues/2535).

Specifically this is a gas efficient implementation of the `diamondCut` function. It uses the least amount of gas to add/replace/remove functions.

The loupe functions are NOT gas optimized. In this implementation the `facets`, `facetFunctionSelectors`, `facetAddresses` loupe functions are not meant to be called on-chain and may use too much gas or run out of gas when called in on-chain transactions.  In this implementation these functions should be called by off-chain software like websites and Javascript libraries etc., where gas costs do not matter.

The `facetAddress` loupe function is gas efficient and can be called in on-chain transactions.
 
The `diamondCut` implementation avoids storage read and writes. Fits 8 function selectors in a single storage slot. This is a gas optimization. 

The `contracts/Diamond.sol` file shows an example of implementing a diamond. 

The `contracts/facets/DiamondFacet.sol` file includes the standard `diamondCut` function and the loupe functions.

The `contracts/libraries/LibDiamondStorage.sol` file shows how to implement Diamond Storage.

The `test/diamondTest.js` file gives tests for the `diamondCut` function and the Diamond Loupe functions.

## How to Get Started Making Your Diamond

1. The most important thing is reading and understanding [EIP-2535 Diamond Standard](https://github.com/ethereum/EIPs/issues/2535). If something is unclear let me know!

2. The second important thing is using the Diamond Standard reference implementation. You are at the right place because this is the README for the reference implementation.

The reference implementation is more than a reference implementation. It is the boilerplate code you need for a diamond. It is tested and it works. Use it. Also, using the reference implementation makes your diamond compliant with the standard.

Specifically you should copy and use the [DiamondFacet.sol](https://github.com/mudgen/Diamond/blob/master/contracts/facets/DiamondFacet.sol) contract as is. It implement the `diamondCut` function and the loupe functions.

The [Diamond.sol](https://github.com/mudgen/Diamond/blob/master/contracts/Diamond.sol) contract could be used as is, or it could be used as a starting point and customized. This contract is the diamond. Its deployment creates a diamond. It's address is a stable diamond address that does not change.

The [LibDiamondStorage.sol](https://github.com/mudgen/Diamond/blob/master/contracts/libraries/LibDiamondStorage.sol) library could be used as is. It shows how to implement Diamond Storage. It includes contract ownership which you might want to change if you want to implement DAO-based ownership or other form of contract ownership. Go for it. Diamonds can work with any kind of contract ownership strategy.

The [LibDiamond.sol](https://github.com/mudgen/Diamond/blob/master/contracts/libraries/LibDiamond.sol) library contains an internal function version of `diamondCut` that can be used in the constructor of a diamond or other places.

## Calling Diamond Functions

In order to call a function that exists in a diamond you need to use the ABI information of the facet that has the function.

Here is an example that uses web3.js:

```javascript
let myUsefulFacet = new web3.eth.Contract(
  MyUsefulFacet.abi, 
  diamondAddress
)
```
In the code above we create a contract variable so we can call contract functions with it.

In this example we know we will use a diamond because we pass a diamond's address as the second argument. But we are using an ABI from the MyUsefulFacet facet so we can call functions that are defined in that facet. MyUsefulFacet's functions must have been added to the diamond (using diamondCut) in order for the diamond to use the function information provided by the ABI of course.

Similarly you need to use the ABI of a facet in Solidity code in order to call functions from a diamond. Here's an example of Solidity code that calls a function from a diamond:

```solidity
string result = MyUsefulFacet(diamondAddress).getResult()
``` 

## Get Help and Join the Community

If you need help or would like to discuss diamonds then send me a message [on twitter](https://twitter.com/mudgen), or [email me](mailto:nick@perfectabstractions.com). Or join the [Diamond Standard Discord server](https://discord.gg/kQewPw2).

## Useful Links

1. [Understanding Diamonds on Ethereum](https://dev.to/mudgen/understanding-diamonds-on-ethereum-1fb)
2. [Solidity Storage Layout For Proxy Contracts and Diamonds](https://medium.com/1milliondevs/solidity-storage-layout-for-proxy-contracts-and-diamonds-c4f009b6903)
3. [New Storage Layout For Proxy Contracts and Diamonds](https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb)
4. [Diamond Setter](https://github.com/lampshade9909/DiamondSetter)
5. [Upgradeable smart contracts using the Diamond Standard](https://hiddentao.com/archives/2020/05/28/upgradeable-smart-contracts-using-diamond-standard)
6. [buidler-deploy supports diamonds](https://github.com/wighawag/buidler-deploy/)


## Author
The diamond standard and reference implementation were written by Nick Mudge.

Contact:

* https://twitter.com/mudgen
* nick@perfectabstractions.com

## License

MIT license. See the license file.
Anyone can use or modify this software for their purposes.
