// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of DiamondLoupe interface.
/******************************************************************************/

import "../libraries/LibDiamondStorage.sol";
import "../interfaces/IDiamondCut.sol";
import "../libraries/LibDiamondCut.sol";

contract DiamondCutFacet is IDiamondCut {
    // Standard diamondCut external function
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// This argument is tightly packed for gas efficiency    
    /// That means no padding with zeros.
    /// Here is the structure of _diamondCut:
    /// _diamondCut = [
    ///     abi.encodePacked(facet, sel1, sel2, sel3, ...),
    ///     abi.encodePacked(facet, sel1, sel2, sel4, ...),
    ///     ...
    /// ]
    /// facet is the address of a facet
    /// sel1, sel2, sel3 etc. are four-byte function selectors.
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(Facet[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {        
        externalCut(_diamondCut);        
        emit DiamondCut(_diamondCut, _init, _calldata);
        if(_calldata.length > 0) {
            address init = _init == address(0)? address(this) : _init;
            // Check that init has contract code
            uint contractSize;
            assembly { contractSize := extcodesize(init) }
            require(contractSize > 0, "DiamondFacet: _init address has no code");
            (bool success, bytes memory error) = init.delegatecall(_calldata);
            if(!success) {
                if(error.length > 0) {
                    // bubble up the error
                    revert(string(error));                    
                }
                else {
                    revert("DiamondFacet: _init function reverted");
                }
            }                        
        }
        // If _init is not address(0) but calldata is empty
        else if(_init != address(0)) {
            revert("DiamondFacet: _calldata is empty");
        }
        // if _calldata is empty and _init is address(0)
        // then skip any initialization                                        
    }
   
    // diamondCut helper function
    // This code is almost the same as the internal diamondCut function, 
    // except it is using 'Facets[] calldata _diamondCut' instead of 
    // 'Facet[] memory _diamondCut', and it does not issue the DiamondCut event.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for two dimensional arrays.
    function externalCut(Facet[] calldata _diamondCut) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(msg.sender == ds.contractOwner, "Must own the contract.");        
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
                        LibDiamondCut.addSelector(newFacetAddress, selector);
                    }
                    // replace
                    else {
                        if(oldFacet != newFacetAddress) {
                            LibDiamondCut.removeSelector(selector);
                            LibDiamondCut.addSelector(newFacetAddress, selector);
                        }
                    }
                }
                
            }
            // remove selectors
            else {
                for(uint selectorIndex; selectorIndex < _diamondCut[facetIndex].functionSelectors.length; selectorIndex++) {                    
                    LibDiamondCut.removeSelector(_diamondCut[facetIndex].functionSelectors[selectorIndex]);
                }
            }
        }        
    }
}