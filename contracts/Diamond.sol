// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of an example of a diamond.
/******************************************************************************/

import "./libraries/LibDiamondStorage.sol";
import "./libraries/LibDiamondCut.sol";
import "./facets/OwnershipFacet.sol";
import "./facets/DiamondCutFacet.sol";
import "./facets/DiamondLoupeFacet.sol";

contract Diamond {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner, IDiamondCut.FacetCut[] memory diamondCut) payable {
        LibDiamondCut.diamondCut(diamondCut, address(0), new bytes(0));

        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        ds.contractOwner = _owner;
        emit OwnershipTransferred(address(0), _owner);   
        
        // adding ERC165 data
        // ERC165
        ds.supportedInterfaces[IERC165.supportsInterface.selector] = true;

        // DiamondCut
        ds.supportedInterfaces[DiamondCutFacet.diamondCut.selector] = true;

        // DiamondLoupe
        bytes4 interfaceID = IDiamondLoupe.facets.selector ^
            IDiamondLoupe.facetFunctionSelectors.selector ^
            IDiamondLoupe.facetAddresses.selector ^
            IDiamondLoupe.facetAddress.selector;
        ds.supportedInterfaces[interfaceID] = true;

        // ERC173
        ds.supportedInterfaces[IERC173.transferOwnership.selector ^ IERC173.owner.selector] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}
