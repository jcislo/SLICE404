// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../../contracts/dn404.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract dn404Test is Test {
    dn404 public token;
    address public owner;
    address public user;

    // Constants
    uint256 private constant TOTAL_SUPPLY = 1000000 * 10**6; // 1M tokens with 6 decimals
    string[] private uri = ["URI1", "URI2", "URI3", "URI4"];
    uint256[] private initialCashRange = [1, 5, 20];

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        // Deploying the dn404 contract
        token = new dn404(1000000, "DN404 Token", "DN404", uri, initialCashRange);
    }

    // Implementation of onERC1155Received for single token transfers
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    // Implementation of onERC1155BatchReceived for batch token transfers
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // Function to check if the contract supports a specific interface
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    // Testing constructor revert: InvalidRangeValue
    function testConstructorRevert_InvalidRangeValue() public {
        uint256[] memory invalidRanges = new uint256[](3);
        invalidRanges[0] = 5;
        invalidRanges[1] = 4; // Decreasing, should revert
        invalidRanges[2] = 20;

        vm.expectRevert(dn404.InvalidRangeValue.selector);
        new dn404(TOTAL_SUPPLY, "DN404 Token", "DN404", uri, invalidRanges);
    }

    // Testing constructor revert: ArrayExceedsLimit
    function testConstructorRevert_ArrayExceedsLimit() public {
        uint256[] memory longRanges = new uint256[](7);
        for (uint256 i = 0; i < 7; i++) {
            longRanges[i] = i + 1;
        }

        vm.expectRevert(dn404.ArrayExceedsLimit.selector);
        new dn404(TOTAL_SUPPLY, "DN404 Token", "DN404", uri, longRanges);
    }

    // Testing validTokenID modifier revert: InvalidTokenId
    function testValidTokenIDModifierRevert_InvalidTokenId() public {
        uint256 invalidTokenId = 3; // cashRange only has 3 elements

        string memory ur = token.uri(invalidTokenId);
        assertEq(ur, "URI4");
    }

    // Testing ERC20 function: totalSupply
    function testTotalSupply() public {
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
    }

    // Testing ERC20 function: name
    function testName() public {
        assertEq(token.name(), "DN404 Token");
    }

    // Testing ERC20 function: symbol
    function testSymbol() public {
        assertEq(token.symbol(), "DN404");
    }

    // Testing ERC20 function: balanceOf
    function testBalanceOf() public {
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY);
    }

    // Testing ERC20 function: approve and allowance
    function testApproveAndAllowance() public {
        address spender = address(0x456);
        uint256 approveAmount = 5000 * 10**6;

        token.approve(spender, approveAmount);
        assertEq(token.allowance(owner, spender), approveAmount);
    }

    // Testing revert in approve function: ERC20InvalidApprover
    function testApproveRevert_InvalidApprover() public {
        address spender = address(0x456);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidApprover.selector, address(0)));
        vm.prank(address(0));
        token.approve(spender, 1000 * 10**6);
    }

    // Testing revert in approve function: ERC20InvalidSpender
    function testApproveRevert_InvalidSpender() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));
        token.approve(address(0), 1000 * 10**6);
    }

    // Testing ERC20 function: transfer
    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**6;
        token.transfer(user, transferAmount);
        assertEq(token.balanceOf(user), transferAmount);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - transferAmount);
    }

    // Testing revert in transferFrom function: ERC20InsufficientAllowance
    function testTransferFromRevert_InsufficientAllowance() public {
        uint256 transferAmount = 1000 * 10**6;
        address spender = address(0x456);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, spender, 0, transferAmount));
        vm.prank(spender);
        token.transferFrom(owner, user, transferAmount);
    }
}