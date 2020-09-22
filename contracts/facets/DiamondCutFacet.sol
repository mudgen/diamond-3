// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
*
* Implementation of diamondCut external function.
/******************************************************************************/

import "../libraries/LibDiamondStorage.sol";
import "../interfaces/IDiamondCut.sol";
import "../libraries/LibDiamondCut.sol";

contract DiamondCutFacet is IDiamondCut {
    // Standard diamondCut external function
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        Facet[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            LibDiamondCut.addReplaceRemoveFacetSelectors(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        if (_init == address(0)) {
            require(_calldata.length == 0, "DiamondCutFacet: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "DiamondCutFacet: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                LibDiamondCut.hasContractCode(_init, "DiamondCutFacet: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("DiamondCutFacet: _init function reverted");
                }
            }
        }
    }
}
