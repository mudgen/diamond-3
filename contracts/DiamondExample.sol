pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

import "./Storage.sol";
import "./DiamondHeaders.sol";
import "./DiamondFacet.sol";
import "./DiamondLoupeFacet.sol";


contract DiamondExample is Storage {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        $contractOwner = msg.sender;        
        emit OwnershipTransferred(address(0), msg.sender);

        // Create a DiamondFacet contract which implements the Diamond interface
        DiamondFacet diamondFacet = new DiamondFacet();

        // Create a DiamondLoupeFacet contract which implements the Diamond Loupe interface
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();   

        bytes[] memory diamondCut = new bytes[](3);

        // Adding cut function
        diamondCut[0] = abi.encodePacked(diamondFacet, Diamond.diamondCut.selector);

        // Adding diamond loupe functions                
        diamondCut[1] = abi.encodePacked(
            diamondLoupeFacet,
            DiamondLoupe.facetFunctionSelectors.selector,
            DiamondLoupe.facets.selector,
            DiamondLoupe.facetAddress.selector,
            DiamondLoupe.facetAddresses.selector            
        );    

        // Adding supportsInterface function
        diamondCut[2] = abi.encodePacked(address(this), ERC165.supportsInterface.selector);

        // execute cut function
        bytes memory cutFunction = abi.encodeWithSelector(Diamond.diamondCut.selector, diamondCut);
        (bool success,) = address(diamondFacet).delegatecall(cutFunction);
        require(success, "Adding functions failed.");        

        // adding ERC165 data
        $supportedInterfaces[ERC165.supportsInterface.selector] = true;
        $supportedInterfaces[Diamond.diamondCut.selector] = true;
        bytes4 interfaceID = DiamondLoupe.facets.selector ^ DiamondLoupe.facetFunctionSelectors.selector ^ DiamondLoupe.facetAddresses.selector ^ DiamondLoupe.facetAddress.selector;
        $supportedInterfaces[interfaceID] = true;
    }

    // This is an immutable functions because it is defined directly in the diamond.
    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return $supportedInterfaces[_interfaceID];
    }

    

    function getArrayLengths() external view returns(uint, uint) {
        return (uint128($selectorSlotsLength) >> 128, uint128($selectorSlotsLength));
    }

    
    function getArray() external view returns(bytes32[] memory) {
        uint selectorSlotsLength = $selectorSlotsLength;
        uint numSelectorsInLastSlot = uint128(selectorSlotsLength >> 128);
        selectorSlotsLength = uint128(selectorSlotsLength);
        bytes32[] memory array = new bytes32[](selectorSlotsLength);
        for(uint i; i < selectorSlotsLength; i++) {
            array[i] = $selectorSlots[i];
        }
        return array;                
    }


    // Finds facet for function that is called and executes the
    // function if it is found and returns any value.
    fallback() external payable {
        address facet = address(bytes20($facets[msg.sig]));
        require(facet != address(0), "Function does not exist.");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), facet, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }

    receive() external payable {
    }
}
  