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

library LibDiamond {
    event DiamondCut(bytes[] _diamondCut, address _init, bytes _calldata);

    // Non-standard internal function version of diamondCut
    // This code is almost the same as externalCut, except it is using
    // 'bytes[] memory _diamondCut' instead of 'bytes[] calldata _diamondCut'
    // and it DOES issue the DiamondCut event
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for an array of bytes arrays.    
    function diamondCut(bytes[] memory _diamondCut) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();        
        for(uint diamondCutIndex; diamondCutIndex < _diamondCut.length; diamondCutIndex++) {            
            bytes memory facetCut = _diamondCut[diamondCutIndex];
            uint numSelectors = (facetCut.length - 20) / 4;
            require(numSelectors > 0, "DiamondFacet: Missing facet or selector info");
            bytes32 slot;            
            assembly {
                // load facet address                
                 slot := mload(add(facetCut,32))
            }
            address newFacet = address(bytes20(slot));
            // position in memory for parsing selectors                        
            uint position = 52;
            // adding or replacing facets
            if(newFacet != address(0)) {               
                uint facetAddressPosition = ds.facetSelectors[newFacet].facetAddressPosition;
                // add newFacet address if it does not exist
                if(facetAddressPosition == 0 && ds.facetSelectors[newFacet].selectors.length == 0) {
                    facetAddressPosition = ds.facetAddresses.length;
                    ds.facetAddresses.push(newFacet);
                    ds.facetSelectors[newFacet].facetAddressPosition = uint16(facetAddressPosition);
                }                
                // add and replace selectors
                for(uint selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly {
                        selector := mload(add(facetCut,position))
                    }
                    position += 4;
                    address oldFacet = ds.selectorToFacetAndPosition[selector].facetAddress;
                    // add
                    if(oldFacet == address(0)) {                        
                        addSelector(newFacet, selector);
                    }
                    // replace
                    else {
                        require(oldFacet != newFacet, "diamondCut: Function cut to same facet");
                        removeSelector(selector);
                        addSelector(newFacet, selector);
                    }
                }
                
            }
            // remove selectors
            else {
                for(uint selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly {
                        selector := mload(add(facetCut,position))
                    }
                    position += 4;
                    removeSelector(selector);
                }

            }
        }
        emit DiamondCut(_diamondCut, address(0), new bytes(0));        
    }

    function addSelector(address _newFacet, bytes4 _selector) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint selectorPosition = ds.facetSelectors[_newFacet].selectors.length;
        ds.facetSelectors[_newFacet].selectors.push(_selector);                        
        ds.selectorToFacetAndPosition[_selector].facetAddress = _newFacet;                        
        ds.selectorToFacetAndPosition[_selector].selectorPosition = uint16(selectorPosition);   
    }

    
    function removeSelector(bytes4 _selector) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        // replace selector with last selector, then delete last selector
        address oldFacet = ds.selectorToFacetAndPosition[_selector].facetAddress;                    
        require(oldFacet != address(0), "diamondCut: Function doesn't exist. Can't remove.");
        uint selectorPosition = ds.selectorToFacetAndPosition[_selector].selectorPosition;
        uint lastSelectorPosition = ds.facetSelectors[oldFacet].selectors.length - 1;
        bytes4 lastSelector = ds.facetSelectors[oldFacet].selectors[lastSelectorPosition];
        if(lastSelector != _selector) {
            ds.facetSelectors[oldFacet].selectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].selectorPosition = uint16(selectorPosition);
        }
        ds.facetSelectors[oldFacet].selectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if(selectorPosition == 1) {
            // replace facet address with last facet address and delete last facet address                                                
            uint lastFacetAddressPosition = ds.facetAddresses.length - 1;
            address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
            uint facetAddressPosition = ds.facetSelectors[oldFacet].facetAddressPosition;
            if(oldFacet != lastFacetAddress) {
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetSelectors[oldFacet];
        }                
    }
    
}
