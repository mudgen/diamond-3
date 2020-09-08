// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

library LibDiamondStorage {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddress {
        address facetAddress;
        uint16 facetAddressPosition; 
    }

    struct DiamondStorage {

        // owner of the contract
        address contractOwner;   

        // maps function selector to the facet address and where the 
        // facet address exists in the facetAddresses array
        mapping(bytes4 => FacetAddress) selectorTofacet;

        // maps facet addresses to function selectors
        mapping(address => bytes4[]) facetSelectors;

        // facet addresses
        address[] facetAddresses;

        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
    }


   struct DiamondStorage {

        // owner of the contract
        address contractOwner;   

        // maps function selector to the facet address and where the 
        // facet address exists in the facetAddresses array
        mapping(bytes4 => FacetAddress) selectorTofacet;

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
