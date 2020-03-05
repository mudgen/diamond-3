pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of Diamond facet.
/******************************************************************************/

import "./Storage.sol";
import "./DiamondHeaders.sol";


contract DiamondFacet is Diamond, Storage {  
    bytes32 constant CLEAR_ADDRESS_MASK = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
    bytes32 constant CLEAR_SELECTOR_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function diamondCut(bytes[] memory _diamondCut) public override {         
        require(msg.sender == $contractOwner, "Must own the contract.");

       uint selectorSlotLengths = $selectorSlotLengths;
       uint selectorSlotsLength = uint128(selectorSlotLengths);       
       uint selectorSlotLength = uint128(selectorSlotLengths >> 128);
       bool slotChange;       
       bytes32 selectorSlot;
       if(selectorSlotLength > 0) {
           selectorSlot = $selectorSlots[selectorSlotsLength-1];
       }

        // loop through diamond cut        
        for(uint diamondCutIndex; diamondCutIndex < _diamondCut.length; diamondCutIndex++) {
            bytes memory facetCut = _diamondCut[diamondCutIndex];
            bytes32 slot;            
            assembly { 
                slot := mload(add(facetCut,32)) 
            }
            bytes32 newFacet = bytes20(slot);            
            uint numSelectors = (facetCut.length - 20) / 4;
            uint position = 52;
            
            // adding or replacing functions
            if(newFacet != 0) {            
                // add and replace selectors
                for(uint selectorIndex; selectorIndex < numSelectors;) {
                    assembly { 
                        slot := mload(add(facetCut,position)) 
                    }
                    position += 32;
                    uint numInSlot;
                    if(numSelectors > 8) {
                        numInSlot = 8;
                    }
                    else {
                        numInSlot = numSelectors;
                    }
                    uint slotIndex;
                    for(; slotIndex < numInSlot; slotIndex++) {
                        bytes4 selector = bytes4(slot << slotIndex * 32);
                        bytes32 oldFacet = $facets[selector];                    
                        // add
                        if(oldFacet == bytes32(0)) {
                            slotChange = true;
                            $facets[selector] = newFacet | bytes32(selectorSlotLength) << 64 | bytes32(selectorSlotsLength-1);
                            selectorSlot &= CLEAR_SELECTOR_MASK >> selectorSlotLength * 32 | bytes32(selector) >> selectorSlotLength * 32;
                            selectorSlotLength++;
                            if(selectorSlotLength == 8) {
                                $selectorSlots[selectorSlotsLength] = selectorSlot;
                                selectorSlotsLength++;
                                selectorSlot = 0;
                                selectorSlotLength = 0;
                            }                            
                        }                    
                        // replace
                        else {
                            require(bytes20(oldFacet) != bytes20(newFacet), "Function cut to same facet.");
                            $facets[selector] = oldFacet & CLEAR_ADDRESS_MASK | newFacet;
                        }
                    }
                    selectorIndex += slotIndex;
                }
            }
            // remove functions
            else {
                slotChange = true;
                for(uint selectorIndex; selectorIndex < numSelectors;) {
                    assembly { 
                        slot := mload(add(facetCut,position)) 
                    }
                    position += 32;
                    uint numInSlot;
                    if(numSelectors > 8) {
                        numInSlot = 8;
                    }
                    else {
                        numInSlot = numSelectors;
                    }
                    uint slotIndex;
                    for(; slotIndex < numInSlot; slotIndex++) {
                        bytes4 selector = bytes4(slot << slotIndex * 32);
                        bytes32 oldFacet = $facets[selector];
                        require(oldFacet != 0, "Function doesn't exist. Can't remove.");
                        if(selectorSlot == 0) {
                            selectorSlot = $selectorSlots[selectorSlotsLength-1];
                            selectorSlotLength = 8;
                        }
                        uint oldSelectorSlotsIndex = uint64(uint(oldFacet));
                        uint oldSelectorSlotIndex = uint64(uint(oldFacet >> 64));
                        bytes32 lastSelector = (selectorSlot >> (8 - selectorSlotLength) * 32) << 224;
                        if(oldSelectorSlotsIndex != selectorSlotsLength-1) {
                            bytes32 oldSelectorSlot = $selectorSlots[oldSelectorSlotsIndex];                            
                            oldSelectorSlot &= CLEAR_SELECTOR_MASK >> oldSelectorSlotIndex * 32 | lastSelector >> oldSelectorSlotIndex * 32;
                            $selectorSlots[oldSelectorSlotsIndex] = oldSelectorSlot;
                            selectorSlotLength--;                            
                        }
                        else {
                            selectorSlot &= CLEAR_SELECTOR_MASK >> oldSelectorSlotIndex * 32 | lastSelector >> oldSelectorSlotIndex * 32;
                            selectorSlotLength--;
                        }
                        if(selectorSlotLength == 0) {
                            selectorSlotsLength--;
                            delete $selectorSlots[selectorSlotsLength];
                            selectorSlot = 0;
                        }
                        if(bytes4(lastSelector) != selector) {                      
                            $facets[bytes4(lastSelector)] = oldFacet & CLEAR_ADDRESS_MASK | $facets[bytes4(lastSelector)]; 
                        }
                        delete $facets[selector];
                    }
                    selectorIndex += slotIndex;
                }
            }
        }
        if(slotChange) {
            if(selectorSlot != 0) {
                $selectorSlots[selectorSlotsLength-1] = selectorSlot;
            }
            $selectorSlotLengths = selectorSlotLength << 128 | selectorSlotsLength;
        }
        emit DiamondCut(_diamondCut);
    }
}
