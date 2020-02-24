pragma solidity ^0.6.3;

contract DiamondStorage {
    // owner of the contract
    address internal $contractOwner;

    // maps function selectors to the facets that execute the functions
    // func selector => facet address
    mapping(bytes4 => address) internal $facets;  

    // array of function selectors
    bytes4[] internal $funcSelectors;  

    // maps each function selector to its position in the funcSelectors array
    // func selector => index
    mapping(bytes4 => uint) internal $funcSelectorToIndex;   
}
