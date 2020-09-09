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
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IERC165.sol";

contract DiamondFacet is IDiamondCut, IDiamondLoupe, IERC165 {
    
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
    function diamondCut(bytes[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {        
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
                    assembly {
                        let errorSize := mload(error)
                        revert(add(32, error), errorSize)
                    }
                }
                else {
                    revert("DiamondFacet: _init function reverted");
                }
            }                        
        }
        else if(_init != address(0)) {
            revert("DiamondFacet: _calldata is empty");
        }                               
    }
   
    // diamondCut helper function
    // This code is almost the same as the internal diamondCut function, 
    // except it is using 'bytes[] calldata _diamondCut' instead of 
    // 'bytes[] memory _diamondCut', and it does not issue the DiamondCut event.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for an array of bytes arrays.
    function externalCut(bytes[] calldata _diamondCut) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(msg.sender == ds.contractOwner, "Must own the contract.");        
        for(uint diamondCutIndex; diamondCutIndex < _diamondCut.length; diamondCutIndex++) {            
            bytes memory facetCut = _diamondCut[diamondCutIndex];
            uint numSelectors = (facetCut.length - 20) / 4;
            require(numSelectors > 0, "DiamondFacet: Missing facet or selector info");
            address newFacet;
            assembly {
                // load facet address                
                 newFacet := mload(add(facetCut,32))
            }
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
    
    
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently
    /// by tools. Therefore the return values are tightly
    /// packed for efficiency. That means no padding with zeros.

    // struct Facet {
    //     address facet;
    //     bytes4[] functionSelectors;
    // }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns(Facet[] memory facets_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for(uint i; i < numFacets; i++) {
            address facetAddress = ds.facetAddresses[i];
            facets_[i].facet = facetAddress;            
            facets_[i].functionSelectors = ds.facetSelectors[facetAddress].selectors;
        }                
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view override returns(bytes4[] memory facetFunctionSelectors_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        facetFunctionSelectors_ = ds.facetSelectors[_facet].selectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns(address[] memory facetAddresses_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        facetAddresses_ = ds.facetAddresses;      
        //facetAddresses_[0] = ds.facetAddresses[0];
        //facetAddresses_[1] = ds.facetAddresses[1];

    }

    
    function test() external view returns (address) {        
        //bytes32 position = LibDiamondStorage.DIAMOND_STORAGE_POSITION;
        //LibDiamondStorage.DiamondStorage storage ds;
        //assembly { ds.slot := position }
        //return ds.selectorToFacetAndPosition[0x52ef6b2c].facetAddress;  
        return address(this);
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns(address facetAddress_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}