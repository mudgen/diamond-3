pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

import "./Storage.sol";
import "./DiamondHeaders.sol";
import "./DiamondFacet.sol";


contract DiamondExample is Storage {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        $contractOwner = msg.sender;        
        emit OwnershipTransferred(address(0), msg.sender);

        // Create a DiamondFacet contract which implements the Diamond and
        // DiamondLoupe interfaces
        DiamondFacet diamondFacet = new DiamondFacet();

        // Two cuts will be created and stored in this array
        DiamondCut[] memory diamondCuts = new DiamondCut[](2);

        FacetCut[] memory facetCuts;
        bytes4[] memory functionSelectors;

        // First Diamond Cut
        // Adding cut function
        functionSelectors = new bytes4[](1);
        functionSelectors[0] = Diamond.cut.selector;
        facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({
            facet: address(diamondFacet),
            action: CutAction.Add,
            functionSelectors: functionSelectors
        });        
        diamondCuts[0] = DiamondCut({
            facetCuts: facetCuts,
            message: "Adding diamond cut function."
        });

        // Second Diamond Cut
        // Adding diamond loupe functions                
        functionSelectors = new bytes4[](6);
        functionSelectors[0] = DiamondLoupe.totalFunctions.selector;
        functionSelectors[1] = DiamondLoupe.functionSelectorByIndex.selector;
        functionSelectors[2] = DiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[3] = DiamondLoupe.facets.selector;
        functionSelectors[4] = DiamondLoupe.facetAddress.selector;
        functionSelectors[5] = DiamondLoupe.facetAddresses.selector;
        facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({
            facet: address(diamondFacet),
            action: CutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCuts[1] = DiamondCut({
            facetCuts: facetCuts,
            message: "Adding diamond loupe functions."
        });        
        // execute cut function
        bytes memory cutFunction = abi.encodeWithSelector(Diamond.cut.selector, diamondCuts);
        (bool success,) = address(diamondFacet).delegatecall(cutFunction);
        require(success, "Adding functions failed.");        
    }

    fallback() external payable {
        address facet = $facets[msg.sig];
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