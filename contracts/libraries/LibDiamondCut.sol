// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
*
* Implementation of internal diamondCut function.
/******************************************************************************/

import "./LibDiamondStorage.sol";
import "../interfaces/IDiamondCut.sol";

library LibDiamondCut {
    event DiamondCut(IDiamondCut.Facet[] _diamondCut, address _init, bytes _calldata);

    // Non-standard internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(IDiamondCut.Facet[] memory _diamondCut) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            addReplaceRemoveFacetSelectors(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
        }
        emit DiamondCut(_diamondCut, address(0), new bytes(0));
    }

    function addReplaceRemoveFacetSelectors(address _newFacetAddress, bytes4[] memory _selectors) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        // add or replace function
        if (_newFacetAddress != address(0)) {
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_newFacetAddress].facetAddressPosition;
            // add new facet address if it does not exist
            if (facetAddressPosition == 0 && ds.facetFunctionSelectors[_newFacetAddress].functionSelectors.length == 0) {
                hasContractCode(_newFacetAddress, "LibDiamondCut: New facet has no code");
                facetAddressPosition = ds.facetAddresses.length;
                ds.facetAddresses.push(_newFacetAddress);
                ds.facetFunctionSelectors[_newFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            // add or replace selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                address oldFacet = ds.selectorToFacetAndPosition[selector].facetAddress;
                // add
                if (oldFacet == address(0)) {
                    addSelector(_newFacetAddress, selector);
                } else {
                    // replace
                    if (oldFacet != _newFacetAddress) {
                        removeSelector(oldFacet, selector);
                        addSelector(_newFacetAddress, selector);
                    }
                }
            }
        } else {
            // remove selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                removeSelector(ds.selectorToFacetAndPosition[selector].facetAddress, selector);
            }
        }
    }

    function addSelector(address _newFacet, bytes4 _selector) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint256 selectorPosition = ds.facetFunctionSelectors[_newFacet].functionSelectors.length;
        ds.facetFunctionSelectors[_newFacet].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _newFacet;
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = uint16(selectorPosition);
    }

    function removeSelector(address _oldFacet, bytes4 _selector) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        // if function does not exist then do nothing and return
        if (_oldFacet == address(0)) {
            return;
        }
        require(_oldFacet != address(this), "LibDiamondCut: Can't remove or replace immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_oldFacet].functionSelectors.length - 1;
        bytes4 lastSelector = ds.facetFunctionSelectors[_oldFacet].functionSelectors[lastSelectorPosition];
        // if not the same then replace _selector with lastSelector
        if (lastSelector != _selector) {
            ds.facetFunctionSelectors[_oldFacet].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_oldFacet].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_oldFacet].facetAddressPosition;
            if (_oldFacet != lastFacetAddress) {
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_oldFacet];
        }
    }

    function hasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
