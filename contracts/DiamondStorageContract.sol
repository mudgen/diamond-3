// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract DiamondStorageContract {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    // slotsLength is the number of 32-byte slots in selectorSlot.
    // lastSlotLength is the number of selectors in the last slot of selectorSlot.
    struct SelectorSlot {
        uint64 slotsLength; // 8-byte
        uint8 lastSlotLength; // 1-byte
    } // total 9-byte

    struct DiamondStorage {
        
        // owner of the contract
        address contractOwner;

        SelectorSlot selectorSlot; // to pack with the address above within one 256-bit

        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to the slot in the selectorSlots array.
        // and maps the selectors to the position in the slot.
        // func selector => address facet, uint64 slotsIndex, uint64 slotIndex
        mapping(bytes4 => bytes32) facets;

        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint => bytes32) selectorSlots;  

        // uint128 numSelectorsInSlot, uint128 selectorSlotsLength
        // selectorSlotsLength is the number of 32-byte slots in selectorSlots.
        // selectorSlotLength is the number of selectors in the last slot of
        // selectorSlots.
        //uint selectorSlotsLength;

        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
    }
    

    function diamondStorage() internal pure returns(DiamondStorage storage ds) {     
        bytes32 position = DIAMOND_STORAGE_POSITION;           
        assembly { ds_slot := position }
    }
}
