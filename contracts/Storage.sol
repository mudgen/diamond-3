pragma solidity ^0.6.3;

contract Storage {
    // owner of the contract
    address internal $contractOwner;

    // maps function selectors to the facets that execute the functions
    // and maps the selectors to the position in the $selectorSlots array
    // func selector => address facet, uint64 selectorIndex
    mapping(bytes4 => bytes32) internal $facets;  

    // array of function selectors    
    mapping(uint => bytes32) internal $selectorSlots;  
    // uint128 selectorSlotLength, uint128 selectorSlotsLength
    // selectorSlotsLength is the number of slots in $selectorSlotLengths;
    // selectorSlotLength is the number of 4 byte slots in the last slot of $selectorSlotLengths;    
    uint $selectorSlotLengths;    
}

/*

contract C {
    struct S {
        uint a;
        uint b;
    }

    bytes32 constant pointer = keccak256(abi.encode(uint(1), uint(0)));

    function data() internal view returns (S storage _data) {
        bytes32 slot = pointer;
        assembly {
            _data_slot := slot
        }
    }
}
*/

