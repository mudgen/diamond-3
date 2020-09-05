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
        SlotInfo memory slot;
        slot.originalSelectorSlotsLength = ds.selectorSlotsLength;
        uint selectorSlotsLength = uint128(slot.originalSelectorSlotsLength);
        uint selectorSlotLength = uint128(slot.originalSelectorSlotsLength >> 128);
        if(selectorSlotLength > 0) {
            slot.selectorSlot = ds.selectorSlots[selectorSlotsLength];
        }
        // loop through diamond cut
        for(uint diamondCutIndex; diamondCutIndex < _diamondCut.length; diamondCutIndex++) {
            bytes memory facetCut = _diamondCut[diamondCutIndex];
            require(facetCut.length > 20, "Missing facet or selector info.");
            bytes32 currentSlot;
            assembly {
                currentSlot := mload(add(facetCut,32))
            }
            bytes32 newFacet = bytes20(currentSlot);
            uint numSelectors = (facetCut.length - 20) / 4;
            uint position = 52;

            // adding or replacing functions
            if(newFacet != 0) {                
                // add and replace selectors
                for(uint selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly {
                        selector := mload(add(facetCut,position))
                    }
                    position += 4;
                    bytes32 oldFacet = ds.facets[selector];
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
            }
            // remove functions
            else {
                slot.updateLastSlot = true;
                for(uint selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly {
                        selector := mload(add(facetCut,position))
                    }
                    position += 4;
                    bytes32 oldFacet = ds.facets[selector];
                    require(oldFacet != 0, "Function doesn't exist. Can't remove.");
                    // Current slot is empty so get the slot before it
                    if(slot.selectorSlot == 0) {
                        selectorSlotsLength--;
                        slot.selectorSlot = ds.selectorSlots[selectorSlotsLength];
                        selectorSlotLength = 8;
                    }
                    slot.oldSelectorSlotsIndex = uint64(uint(oldFacet));
                    slot.oldSelectorSlotIndex = uint32(uint(oldFacet >> 64));
                    // gets the last selector in the slot
                    bytes4 lastSelector = bytes4(slot.selectorSlot << (selectorSlotLength-1) * 32);
                    if(slot.oldSelectorSlotsIndex != selectorSlotsLength) {
                        slot.oldSelectorSlot = ds.selectorSlots[slot.oldSelectorSlotsIndex];
                        // clears the selector we are deleting and puts the last selector in its place.
                        slot.oldSelectorSlot = slot.oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> slot.oldSelectorSlotIndex * 32) | bytes32(lastSelector) >> slot.oldSelectorSlotIndex * 32;
                        // update storage with the modified slot
                        ds.selectorSlots[slot.oldSelectorSlotsIndex] = slot.oldSelectorSlot;
                        selectorSlotLength--;
                    }
                    else {
                        // clears the selector we are deleting and puts the last selector in its place.
                        slot.selectorSlot = slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> slot.oldSelectorSlotIndex * 32) | bytes32(lastSelector) >> slot.oldSelectorSlotIndex * 32;
                        selectorSlotLength--;                        
                    }
                    if(selectorSlotLength == 0) {
                        delete ds.selectorSlots[selectorSlotsLength];
                        slot.selectorSlot = 0;                        
                    }
                    if(lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = oldFacet & CLEAR_ADDRESS_MASK | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                }
            }
        }
        uint newSelectorSlotsLength = selectorSlotLength << 128 | selectorSlotsLength;
        if(newSelectorSlotsLength != slot.originalSelectorSlotsLength) {
            ds.selectorSlotsLength = newSelectorSlotsLength;
        }
        if(slot.updateLastSlot && selectorSlotLength > 0) {
            ds.selectorSlots[selectorSlotsLength] = slot.selectorSlot;
        }        
    }

    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently
    /// by tools. Therefore the return values are tightly
    /// packed for efficiency. That means no padding with zeros.

    struct Facet {
        address facet;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facets and their selectors.
    /// @return An array of bytes arrays containing each facet
    ///         and each facet's selectors.
    /// The return value is tightly packed.
    /// That means no padding with zeros.
    /// Here is the structure of the return value:
    /// returnValue = [
    ///     abi.encodePacked(facet, sel1, sel2, sel3, ...),
    ///     abi.encodePacked(facet, sel1, sel2, sel3, ...),
    ///     ...
    /// ]
    /// facet is the address of a facet.
    /// sel1, sel2, sel3 etc. are four-byte function selectors.
    function facets() external view override returns(bytes[] memory) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint totalSelectorSlots = ds.selectorSlotsLength;        
        uint totalSelectors = uint128(totalSelectorSlots) * 8 + uint128(totalSelectorSlots >> 128);
        
        // get default size of arrays
        uint defaultSize = totalSelectors;
        if(defaultSize > 20) {
            defaultSize = 20;
        }
        Facet[] memory facets_ = new Facet[](defaultSize);
        uint8[] memory numFacetSelectors = new uint8[](defaultSize);
        uint numFacets;
        uint selectorCount;
        // loop through function selectors
        for(uint slotIndex; selectorCount < totalSelectors; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for(uint selectorIndex; selectorIndex < 8; selectorIndex++) {
                selectorCount++;
                if(selectorCount > totalSelectors) {
                    break;
                }
                bytes4 selector = bytes4(slot << selectorIndex * 32);
                address facet = address(bytes20(ds.facets[selector]));
                bool continueLoop = false;
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
        }
        bytes[] memory returnFacets = new bytes[](numFacets);
        for(uint facetIndex; facetIndex < numFacets; facetIndex++) {
            uint numSelectors = numFacetSelectors[facetIndex];
            bytes memory selectorsBytes = new bytes(4 * numSelectors);
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            uint bytePosition;
            for(uint i; i < numSelectors; i++) {
                for(uint j; j < 4; j++) {
                    selectorsBytes[bytePosition] = byte(selectors[i] << j * 8);
                    bytePosition++;
                }
            }
            returnFacets[facetIndex] = abi.encodePacked(facets_[facetIndex].facet, selectorsBytes);
        }
        return returnFacets;
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return A bytes array of function selectors.
    /// The return value is tightly packed. Here is an example:
    /// return abi.encodePacked(selector1, selector2, selector3, ...)
    function facetFunctionSelectors(address _facet) external view override returns(bytes memory) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint totalSelectorSlots = ds.selectorSlotsLength;
        uint totalSelectors = uint128(totalSelectorSlots) * 8 + uint128(totalSelectorSlots >> 128);
        
        uint numFacetSelectors;
        bytes4[] memory facetSelectors = new bytes4[](totalSelectors);
        uint selectorCount;
        // loop through function selectors
        for(uint slotIndex; selectorCount < totalSelectors; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for(uint selectorIndex; selectorIndex < 8; selectorIndex++) {
                selectorCount++;
                if(selectorCount > totalSelectors) {
                    break;
                }
                bytes4 selector = bytes4(slot << selectorIndex * 32);
                address facet = address(bytes20(ds.facets[selector]));
                if(_facet == facet) {
                    facetSelectors[numFacetSelectors] = selector;
                    numFacetSelectors++;
                }
            }
        }
        bytes memory returnBytes = new bytes(4 * numFacetSelectors);
        uint bytePosition;
        for(uint i; i < numFacetSelectors; i++) {
            for(uint j; j < 4; j++) {
                returnBytes[bytePosition] = byte(facetSelectors[i] << j * 8);
                bytePosition++;
            }
        }
        return returnBytes;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return A byte array of tightly packed facet addresses.
    /// Example return value:
    /// return abi.encodePacked(facet1, facet2, facet3, ...)
    function facetAddresses() external view override returns(bytes memory) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint totalSelectorSlots = ds.selectorSlotsLength;
        uint totalSelectors = uint128(totalSelectorSlots) * 8 + uint128(totalSelectorSlots >> 128);
        
        address[] memory facets_ = new address[](totalSelectors);
        uint numFacets;
        uint selectorCount;
        // loop through function selectors
        for(uint slotIndex; selectorCount < totalSelectors; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for(uint selectorIndex; selectorIndex < 8; selectorIndex++) {
                selectorCount++;
                if(selectorCount > totalSelectors) {
                    break;
                }
                bytes4 selector = bytes4(slot << selectorIndex * 32);
                address facet = address(bytes20(ds.facets[selector]));
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
        }

        bytes memory returnBytes = new bytes(20 * numFacets);
        uint bytePosition;
        for(uint i; i < numFacets; i++) {
            for(uint j; j < 20; j++) {
                returnBytes[bytePosition] = byte(bytes20(facets_[i]) << j * 8);
                bytePosition++;
            }
        }
        return returnBytes;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns(address) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        return address(bytes20(ds.facets[_functionSelector]));
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}