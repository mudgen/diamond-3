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

    // Constants used by diamondCut
    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint(0xffffffffffffffffffffffff));                                                                     
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint(0xffffffff << 224));

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

    // This struct is used to prevent getting the error "CompilerError: Stack too deep, try removing local variables."
    // See this article: https://medium.com/1milliondevs/compilererror-stack-too-deep-try-removing-local-variables-solved-a6bcecc16231
    struct SlotInfo {
        uint originalSelectorSlotsLength;
        bytes32 selectorSlot;
        uint oldSelectorSlotsIndex;
        uint oldSelectorSlotIndex;
        bytes32 oldSelectorSlot;
        bool updateLastSlot;
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
        uint position;
        for(uint diamondCutIndex; diamondCutIndex < _diamondCut.length; diamondCutIndex++) {
            uint numSelectors;
            {
                bytes calldata facetCut = _diamondCut[diamondCutIndex];
                require(facetCut.length > 20, "DiamondFacet: Missing facet or selector info");
                numSelectors = (facetCut.length - 20) / 4;
            }
            position += 32;
            bytes32 newFacet;            
            assembly {
                // load facet address
                // and() to clear bits after first 20 bytes
                newFacet := and(calldataload(position), 0xffffffffffffffffffffffffffffffffffffffff)
                position := add(position,20)
            }                        
            if(newFacet != 0) {               
                if(ds.facetSelectors[newFacet].length == 0) {
                    ds.facetAddresses.push(address(newFacet));
                }
                /*
                // add and replace selectors
                for(uint selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly {
                        selector := calldataload(position)
                    }
                    position += 4;
                    bytes32 oldFacet = ds.selectorToFacet[selector];
                    // add
                    if(oldFacet == 0) {
                        // update the last slot at then end of the function
                        slot.updateLastSlot = true;
                        ds.facets[selector] = newFacet | bytes32(selectorSlotLength) << 64 | bytes32(selectorSlotsLength);
                        // clear selector position in slot and add selector
                        slot.selectorSlot = slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorSlotLength * 32) | bytes32(selector) >> selectorSlotLength * 32;
                        selectorSlotLength++;
                        // if slot is full then write it to storage
                        if(selectorSlotLength == 8) {
                            ds.selectorSlots[selectorSlotsLength] = slot.selectorSlot;
                            slot.selectorSlot = 0;
                            selectorSlotLength = 0;
                            selectorSlotsLength++;
                        }
                    }
                    // replace
                    else {
                        require(bytes20(oldFacet) != bytes20(newFacet), "Function cut to same facet.");
                        // replace old facet address
                        ds.facets[selector] = oldFacet & CLEAR_ADDRESS_MASK | newFacet;
                    }
                }
                */
            }


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
            facets_[i].functionSelectors = ds.facetSelectors[facetAddress];
        }                
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view override returns(bytes4[] memory facetFunctionSelectors_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        facetFunctionSelectors_ = ds.facetSelectors[_facet];
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns(address[] memory facetAddresses_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        facetAddresses_ = ds.facetAddresses  ;      
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns(address facetAddress_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        return address(bytes20(ds.selectorToFacet[_functionSelector]));
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}