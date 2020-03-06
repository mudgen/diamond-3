pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of Diamond facet.
* This is gas optimized by reducing storage reads and storage writes.
/******************************************************************************/

import "./Storage.sol";
import "./DiamondHeaders.sol";


contract DiamondFacet is Diamond, Storage {  
    bytes32 constant CLEAR_ADDRESS_MASK = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
    bytes32 constant CLEAR_SELECTOR_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;

    struct SlotInfo {
        uint selectorSlotsLength;
        uint numSelectorsInLastSlot;
        bytes32 selectorSlot;
        uint oldSelectorSlotsIndex;
        uint oldSelectorsInLastSlotIndex;
        bytes32 oldSelectorSlot;
        bool slotChange;
    }

    function diamondCut(bytes[] memory _diamondCut) public override {         
        require(msg.sender == $contractOwner, "Must own the contract.");
        SlotInfo memory slot = SlotInfo($selectorSlotsLength,0,0,0,0,0,false);
        slot.numSelectorsInLastSlot = uint128(slot.selectorSlotsLength >> 128);
        slot.selectorSlotsLength = uint128(slot.selectorSlotsLength);                
        if(slot.numSelectorsInLastSlot > 0) {
            slot.selectorSlot = $selectorSlots[slot.selectorSlotsLength-1];
        }

        // loop through diamond cut        
        for(uint diamondCutIndex; diamondCutIndex < _diamondCut.length; diamondCutIndex++) {
            bytes memory facetCut = _diamondCut[diamondCutIndex];
            require(facetCut.length != 0, "Missing facet/selector info.");
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
                for(uint selectorIndex; selectorIndex < numSelectors;) {
                    assembly { 
                        currentSlot := mload(add(facetCut,position)) 
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
                        bytes4 selector = bytes4(currentSlot << slotIndex * 32);
                        bytes32 oldFacet = $facets[selector];                    
                        // add
                        if(oldFacet == 0) {
                            slot.slotChange = true;
                            if(slot.numSelectorsInLastSlot == 0) {
                                slot.selectorSlotsLength++;
                            }
                            $facets[selector] = newFacet | bytes32(slot.numSelectorsInLastSlot) << 64 | bytes32(slot.selectorSlotsLength-1);                            
                            slot.selectorSlot = slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> slot.numSelectorsInLastSlot * 32) | bytes32(selector) >> slot.numSelectorsInLastSlot * 32;                            
                            slot.numSelectorsInLastSlot++;
                            if(slot.numSelectorsInLastSlot == 8) {
                                $selectorSlots[slot.selectorSlotsLength] = slot.selectorSlot;                                
                                slot.selectorSlot = 0;
                                slot.numSelectorsInLastSlot = 0;
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
                slot.slotChange = true;
                for(uint selectorIndex; selectorIndex < numSelectors;) {
                    assembly { 
                        currentSlot := mload(add(facetCut,position)) 
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
                        bytes4 selector = bytes4(currentSlot << slotIndex * 32);
                        bytes32 oldFacet = $facets[selector];
                        require(oldFacet != 0, "Function doesn't exist. Can't remove.");
                        if(slot.selectorSlot == 0) {
                            slot.selectorSlot = $selectorSlots[slot.selectorSlotsLength-1];
                            slot.numSelectorsInLastSlot = 8;
                        }
                        slot.oldSelectorSlotsIndex = uint64(uint(oldFacet));
                        slot.oldSelectorsInLastSlotIndex = uint64(uint(oldFacet >> 64));
                        bytes32 lastSelector = (slot.selectorSlot >> (8 - slot.numSelectorsInLastSlot) * 32) << 224;
                        if(slot.oldSelectorSlotsIndex != slot.selectorSlotsLength-1) {
                            slot.oldSelectorSlot = $selectorSlots[slot.oldSelectorSlotsIndex];                            
                            slot.oldSelectorSlot = slot.oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> slot.oldSelectorsInLastSlotIndex * 32) | lastSelector >> slot.oldSelectorsInLastSlotIndex * 32;
                            $selectorSlots[slot.oldSelectorSlotsIndex] = slot.oldSelectorSlot;
                            slot.numSelectorsInLastSlot--;                            
                        }
                        else {
                            slot.selectorSlot = slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> slot.oldSelectorsInLastSlotIndex * 32) | lastSelector >> slot.oldSelectorsInLastSlotIndex * 32;
                            slot.numSelectorsInLastSlot--;
                        }
                        if(slot.numSelectorsInLastSlot == 0) {
                            slot.selectorSlotsLength--;
                            delete $selectorSlots[slot.selectorSlotsLength];
                            slot.selectorSlot = 0;
                        }
                        if(bytes4(lastSelector) != selector) {                      
                            $facets[bytes4(lastSelector)] = oldFacet & CLEAR_ADDRESS_MASK | bytes20($facets[bytes4(lastSelector)]); 
                        }
                        delete $facets[selector];
                    }
                    selectorIndex += slotIndex;
                }
            }
        }
        if(slot.slotChange) {
            if(slot.selectorSlot != 0) {
                $selectorSlots[slot.selectorSlotsLength-1] = slot.selectorSlot;
            }
            $selectorSlotsLength = slot.numSelectorsInLastSlot << 128 | slot.selectorSlotsLength;
        }
        emit DiamondCut(_diamondCut);
    }
}
