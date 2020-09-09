// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

library LibDiamondStorage {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 facetPosition;
        uint16 selectorPosition;
    }  

    struct DiamondStorage {

        // owner of the contract
        address contractOwner;

        // Holds the facet address and selectors for each facet in the diamond
        Facet[] facets;

        // maps function selector to facet address and its position
        // in the facets array
        // function selector => facet address and position in facets array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacet;

        // maps facetAddress to it position in the facets array
        // Values are facetPosition+1, and 0 indicates facet address is not in facets array
        // facetAddress => position in facets array
        mapping(address => uint) facetPosition;
        
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
    }


    function diamondStorage() internal pure returns(DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly { ds.slot := position }
    }
}
