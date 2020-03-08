pragma solidity ^0.6.3;

contract Storage {
    // owner of the contract
    address internal $contractOwner;

    // maps function selectors to the facets that execute the functions
    // and maps the selectors to the slot in the $selectorSlots array
    // and maps the selectors to the position in the slot
    // func selector => address facet, uint64 slotsIndex, uint64 slotIndex
    mapping(bytes4 => bytes32) internal $facets;  

    // array of slots of function selectors    
    // each slot holds 8 function selectors
    mapping(uint => bytes32) internal $selectorSlots;  

    // uint128 numSelectorsInSlot, uint128 selectorSlotsLength
    // selectorSlotsLength is the number of slots in $selectorSlotLength;
    // selectorSlotLength is the number of selectors in the last slot of
    // $selectorSlots;    
    uint $selectorSlotsLength;    

    /// Use to query if a contract implements an interface.
    /// Used to implement ERC-165.
    mapping(bytes4 => bool) $supportedInterfaces;
}
