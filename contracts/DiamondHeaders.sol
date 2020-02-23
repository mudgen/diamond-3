pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

enum CutAction {Add, Replace, Remove}

struct FacetCut {
    address facet;
    CutAction action;
    bytes4[] functionSelectors;
}

struct DiamondCut {
    FacetCut[] facetCuts;
    string message;
}

interface Diamond {
    event DiamondCuts(DiamondCut[] _diamondCuts);    
    function cut(DiamondCut[] calldata _diamondCuts) external;
}

// A loupe is a small magnifying glass used to look at diamonds.
// These functions are used to look at diamond contracts
interface DiamondLoupe {    
    struct Facet {
        address facet;
        bytes4[] functionSelectors;
    }
    function totalFunctions() external view returns(uint);
    function functionSelectorByIndex(uint _index) external view returns(bytes4 functionSelector, address facet);    
    function facetFunctionSelectors(address _facet) external view returns(bytes4[] memory);
    function facets() external view returns(Facet[] memory);
    function facetAddress(bytes4 _functionSelector) external view returns(address);
    function facetAddresses() external view returns(address[] memory);
}