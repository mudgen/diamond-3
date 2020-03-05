pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of Diamond facet.
/******************************************************************************/

import "./Storage.sol";
import "./DiamondHeaders.sol";

contract DiamondLoupeFacet is DiamondLoupe, Storage {  

    function facets() external view override returns(Facet[] memory) {
        // get default size of arrays
        uint defaultSize = $funcSelectors.length;        
        if(defaultSize > 20) {
            defaultSize = 20;
        }
        Facet[] memory facets_ = new Facet[](defaultSize);
        uint8[] memory numFacetSelectors = new uint8[](defaultSize);
        uint numFacets;
        // loop through function selectors
        for(uint selectorsIndex; selectorsIndex < $funcSelectors.length; selectorsIndex++) {
            bytes4 selector = $funcSelectors[selectorsIndex];
            address facet = $facets[selector];
            bool continueLoop = false;     
            // loop through collected facets
            for(uint facetIndex; facetIndex < numFacets; facetIndex++) {
                if(facets_[facetIndex].facet == facet) {                    
                    uint arrayLength = facets_[facetIndex].functionSelectors.length;
                    // if array is too small then enlarge it
                    if(numFacetSelectors[facetIndex]+1 > arrayLength) {
                        bytes4[] memory biggerArray = new bytes4[](arrayLength + defaultSize);
                        // copy contents of old array
                        for(uint i; i < arrayLength; i++) {
                            biggerArray[i] = facets_[facetIndex].functionSelectors[i];
                        }
                        facets_[facetIndex].functionSelectors = biggerArray;
                    }
                    facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                    // probably will never have more than 255 functions from one facet contract
                    require(numFacetSelectors[facetIndex] < 255);
                    numFacetSelectors[facetIndex]++;
                    continueLoop = true;
                    break;
                }
            }
            if(continueLoop) {
                continueLoop = false;
                continue;
            }
            uint arrayLength = facets_.length;
            // if array is too small then enlarge it
            if(numFacets+1 > arrayLength) {
                Facet[] memory biggerArray = new Facet[](arrayLength + defaultSize);
                uint8[] memory biggerArray2 = new uint8[](arrayLength + defaultSize);
                for(uint i; i < arrayLength; i++) {
                    biggerArray[i] = facets_[i];
                    biggerArray2[i] = numFacetSelectors[i];        
                }
                facets_ = biggerArray;
                numFacetSelectors = biggerArray2;        
            }
            facets_[numFacets].facet = facet;
            facets_[numFacets].functionSelectors = new bytes4[](defaultSize);
            facets_[numFacets].functionSelectors[0] = selector;            
            numFacetSelectors[numFacets] = 1;
            numFacets++;
        }
        uint difference = facets_.length - numFacets;
        // shorten the array
        assembly {
            mstore(facets_, sub(mload(facets_), difference))
        }
        for(uint facetIndex; facetIndex < numFacets; facetIndex++) {
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            difference = selectors.length - numFacetSelectors[facetIndex];
            // shorten the array
            assembly {
                mstore(selectors, sub(mload(selectors), difference))
            }
        }
        return facets_;
    }
   
    function facetFunctionSelectors(address _facet) external view override returns(bytes4[] memory) {
        uint funcSelectorsLength = $funcSelectors.length;
        uint numFacetSelectors;        
        bytes4[] memory facetSelectors = new bytes4[](funcSelectorsLength);        
        for(uint selectorsIndex; selectorsIndex < funcSelectorsLength; selectorsIndex++) {
            bytes4 selector = $funcSelectors[selectorsIndex];            
            if(_facet == $facets[selector]) {
                facetSelectors[numFacetSelectors] = selector;          
                numFacetSelectors++;
            }
        }
        // shorten array
        uint difference = funcSelectorsLength - numFacetSelectors;
        assembly {
            mstore(facetSelectors, sub(mload(facetSelectors), difference))
        }
        return facetSelectors;
    }

    function facetAddresses() external view override returns(address[] memory) {
        uint funcSelectorsLength = $funcSelectors.length;
        address[] memory facets_ = new address[](funcSelectorsLength);
        uint numFacets;        
         for(uint selectorsIndex; selectorsIndex < funcSelectorsLength; selectorsIndex++) {
            address facet = $facets[$funcSelectors[selectorsIndex]]; 
            bool continueLoop = false;
            for(uint facetIndex; facetIndex < numFacets; facetIndex++) {
                if(facet == facets_[facetIndex]) {
                    continueLoop = true;
                    break;
                }
            }
            if(continueLoop) {
                continueLoop = false;
                continue;
            }
            facets_[numFacets] = facet;
            numFacets++;            
        }
        // shorten array
        uint difference = funcSelectorsLength - numFacets;
        assembly {
            mstore(facets_, sub(mload(facets_), difference))
        }
        return facets_;
    }

    function facetAddress(bytes4 _functionSelector) external view override returns(address) {
        return $facets[_functionSelector];    
    }

    
}