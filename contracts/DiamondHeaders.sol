pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

/*
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
    function cut(DiamondCut[] calldata _diamondCuts) external;
    event DiamondCuts(DiamondCut[] _diamondCuts);    
}
*/


interface Diamond {
    /// _faceCuts is an array of bytes arrays.
    /// This argument is tightly-packed for gas efficiency
    /// Here is the structure of _faceCuts:
    /// _faceCuts = [
    ///     abi.encodePacked(facet, functionSelectors),
    ///     abi.encodePacked(facet, functionSelectors),
    ///     ...
    /// ]    
    /// facet is the address of a facet    
    /// functionSelectors consists of one or more 4 byte function selectors    
    function diamondCut(bytes[] calldata _diamondCut) external;
    event DiamondCut(bytes[] _diamondCut);    
}



contract Test {
    bytes m = abi.encodePacked(address(0), uint(0), 
        bytes4(0x34343434), bytes4(0x34343434), bytes4(0x34343434));
}

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface DiamondLoupe {    
    struct Facet {
        address facet;
        bytes4[] functionSelectors;
    }    
    function facets() external view returns(Facet[] memory);
    function facetFunctionSelectors(address _facet) external view returns(bytes4[] memory);
    function facetAddresses() external view returns(address[] memory);
    function facetAddress(bytes4 _functionSelector) external view returns(address);    
}