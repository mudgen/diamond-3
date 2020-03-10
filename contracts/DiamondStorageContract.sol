pragma solidity ^0.6.4;

contract DiamondStorageContract {

    struct DiamondStorage {
        // owner of the contract
        address contractOwner;

        // maps function selectors to the facets that execute the functions
        // and maps the selectors to the slot in the selectorSlots array
        // and maps the selectors to the position in the slot
        // func selector => address facet, uint64 slotsIndex, uint64 slotIndex
        mapping(bytes4 => bytes32) facets;

        // array of slots of function selectors    
        // each slot holds 8 function selectors
        mapping(uint => bytes32) selectorSlots;  

        // uint128 numSelectorsInSlot, uint128 selectorSlotsLength
        // selectorSlotsLength is the number of slots in selectorSlotLength;
        // selectorSlotLength is the number of selectors in the last slot of
        // $selectorSlots;    
        uint selectorSlotsLength;

        /// Use to query if a contract implements an interface.
        /// Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 constant location = keccak256("diamond.standard.diamond.storage");

    function diamondStorage() internal pure returns(DiamondStorage storage ds) {
        bytes32 loc = location;
        assembly {
            ds_slot := loc
        }
    }


}