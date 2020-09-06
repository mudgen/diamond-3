// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

library LibDiamondStorage {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {

        // owner of the contract
        address contractOwner;

        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to the slot in the selectorSlots array.
        // and maps the selectors to the position in the slot.
        // func selector => address facet, uint32 slotIndex, uint64 slotsIndex
        mapping(bytes4 => bytes32) selectorTofacet;

        // maps facet addresses to function selectors
        mapping(address => bytes4[]) facetSelectors;

        // facet addresses
        address[] facetAddresses;

        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
    }


    function diamondStorage() internal pure returns(DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly { ds.slot := position }
    }
}
