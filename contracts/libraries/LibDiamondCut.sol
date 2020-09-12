// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of Diamond facet.
* This is gas optimized by reducing storage reads and storage writes.
* This code is as complex as it is to reduce gas costs.
/******************************************************************************/

import { LibDiamondStorage } from "./LibDiamondStorage.sol";

library LibDiamondCut {
    
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }
    
    event DiamondCut(Facet[] _diamondCut, address _init, bytes _calldata);  

    // Non-standard internal function version of diamondCut
    // This code is almost the same as externalCut, except it is using
    // 'bytes[] memory _diamondCut' instead of 'bytes[] calldata _diamondCut'
    // and it DOES issue the DiamondCut event
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.    
    function diamondCut(Facet[] memory _diamondCut) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();      
        for(uint facetIndex; facetIndex < _diamondCut.length; facetIndex++) {                        
            address newFacetAddress = _diamondCut[facetIndex].facetAddress;
            // add or replace function
            if(newFacetAddress != address(0)) {               
                uint facetAddressPosition = ds.facetFunctionSelectors[newFacetAddress].facetAddressPosition;
                // add new facet address if it does not exist
                if(facetAddressPosition == 0 && ds.facetFunctionSelectors[newFacetAddress].functionSelectors.length == 0) {
                    facetAddressPosition = ds.facetAddresses.length;
                    ds.facetAddresses.push(newFacetAddress);
                    ds.facetFunctionSelectors[newFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
                }                
                // add or replace selectors
                for(uint selectorIndex; selectorIndex < _diamondCut[facetIndex].functionSelectors.length; selectorIndex++) {
                    bytes4 selector = _diamondCut[facetIndex].functionSelectors[selectorIndex];
                    address oldFacet = ds.selectorToFacetAndPosition[selector].facetAddress;
                    // add
                    if(oldFacet == address(0)) {                        
                        addSelector(newFacetAddress, selector);
                    }
                    // replace
                    else {
                        if(oldFacet != newFacetAddress) {
                            removeSelector(selector);
                            addSelector(newFacetAddress, selector);
                        }
                    }
                }
                
            }
            // remove selectors
            else {
                for(uint selectorIndex; selectorIndex < _diamondCut[facetIndex].functionSelectors.length; selectorIndex++) {                    
                    removeSelector(_diamondCut[facetIndex].functionSelectors[selectorIndex]);
                }

            }
        }   
        emit DiamondCut(_diamondCut, address(0), new bytes(0));        
    }

    function addSelector(address _newFacet, bytes4 _selector) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint selectorPosition = ds.facetFunctionSelectors[_newFacet].functionSelectors.length;
        ds.facetFunctionSelectors[_newFacet].functionSelectors.push(_selector);                        
        ds.selectorToFacetAndPosition[_selector].facetAddress = _newFacet;                        
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = uint16(selectorPosition);   
    }

    
    function removeSelector(bytes4 _selector) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();        
        address oldFacet = ds.selectorToFacetAndPosition[_selector].facetAddress;                    
        // if function does not exist then do nothing and return            
        if(oldFacet == address(0)) {
            return;
        }
        // replace selector with last selector, then delete last selector
        uint selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint lastSelectorPosition = ds.facetFunctionSelectors[oldFacet].functionSelectors.length - 1;
        bytes4 lastSelector = ds.facetFunctionSelectors[oldFacet].functionSelectors[lastSelectorPosition];
        // if not the same then replace _selector with lastSelector
        if(lastSelector != _selector) {
            ds.facetFunctionSelectors[oldFacet].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[oldFacet].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if(lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address                                                
            uint lastFacetAddressPosition = ds.facetAddresses.length - 1;
            address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
            uint facetAddressPosition = ds.facetFunctionSelectors[oldFacet].facetAddressPosition;
            if(oldFacet != lastFacetAddress) {
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[oldFacet];
        }                
    }
    
}
