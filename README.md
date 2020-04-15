# Diamond Standard Reference Implementation
This is the gas-optimized reference implementation for the [diamond standard](https://github.com/ethereum/EIPs/issues/2535).

Specifically this is a gas efficient implementation of the `diamondCut` function and the Diamond Loupe functions from the diamond standard.

The `diamondCut` implementation avoids storage read and writes. Fits 8 function selectors in a single storage slot. This is a gas optimization.

The `contracts/DiamondExample.sol` file shows an example of implementing a diamond.

The `test/diamondExampleTest.js` file gives tests for the `diamondCut` function and the Diamond Loupe functions.

## Author
The diamond standard and reference implementation were written by Nick Mudge.

Contact:

* https://twitter.com/mudgen
* nick@perfectabstractions.com

## License

MIT license. See the license file.
Anyone can use or modify this software for their purposes.
