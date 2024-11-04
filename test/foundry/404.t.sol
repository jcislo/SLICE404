// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../contracts/dn404.sol"; 

contract DN404Test is Test {
    dn404 public contractUnderTest;
    address owner;
    address addr1;
    address addr2;
    uint256[] range = [1, 5, 20];
    string[] uris = ["uri1", "uri2", "uri3", "uri4", "uri5", "uri6"];

    function setUp() public {
        owner = address(this);
        addr1 = address(0x1);
        addr2 = address(0x2);

        contractUnderTest = new dn404(
            519,          // _totalSupply
            "Digital Dollar",
            "USD",
            uris,
            range
        );
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

    function testConstructor() public {
        uint256 balFung = contractUnderTest.balanceOf(owner);
        uint256 balOnes = contractUnderTest.balanceOf(owner, 1);
        uint256 balFives = contractUnderTest.balanceOf(owner, 2);
        uint256 balTwenties = contractUnderTest.balanceOf(owner, 3);

        assertEq(balFung, 519 * (10 ** 6));
        assertEq(balOnes, 4);
        assertEq(balFives, 3);
        assertEq(balTwenties, 25);
    }

    function testTransferERC20() public {
        contractUnderTest.transfer(addr1, 5 * (10 ** 6));

        uint256 balFung = contractUnderTest.balanceOf(owner);
        uint256 balOnes = contractUnderTest.balanceOf(owner, 1);
        uint256 balFives = contractUnderTest.balanceOf(owner, 2);
        uint256 balTwenties = contractUnderTest.balanceOf(owner, 3);

        assertEq(balFung, 514 * (10 ** 6));
        assertEq(balOnes, 4);
        assertEq(balFives, 2);
        assertEq(balTwenties, 25);

        uint256 balFungUser = contractUnderTest.balanceOf(addr1);
        uint256 balOnesUser = contractUnderTest.balanceOf(addr1, 1);
        uint256 balFivesUser = contractUnderTest.balanceOf(addr1, 2);
        uint256 balTwentiesUser = contractUnderTest.balanceOf(addr1, 3);
        assertEq(balFungUser, 5 * (10 ** 6));
        assertEq(balOnesUser, 0);
        assertEq(balFivesUser, 1);
        assertEq(balTwentiesUser, 0);
    }

    function testTransferAdditionalERC20() public {
        contractUnderTest.transfer(addr1, 24 * (10 ** 6));

        uint256 balFung = contractUnderTest.balanceOf(owner);
        uint256 balOnes = contractUnderTest.balanceOf(owner, 1);
        uint256 balFives = contractUnderTest.balanceOf(owner, 2);
        uint256 balTwenties = contractUnderTest.balanceOf(owner, 3);

        assertEq(balFung, 495 * (10 ** 6));
        assertEq(balOnes, 0);
        assertEq(balFives, 3);
        assertEq(balTwenties, 24);

        uint256 balFungUser = contractUnderTest.balanceOf(addr1);
        uint256 balOnesUser = contractUnderTest.balanceOf(addr1, 1);
        uint256 balFivesUser = contractUnderTest.balanceOf(addr1, 2);
        uint256 balTwentiesUser = contractUnderTest.balanceOf(addr1, 3);
        assertEq(balFungUser, 24 * (10 ** 6));
        assertEq(balOnesUser, 4);
        assertEq(balFivesUser, 0);
        assertEq(balTwentiesUser, 1);
    }

    /// @notice Fuzz test to transfer random amounts of ERC20 tokens and validate corresponding NFT balances
    /// @param amount The amount of fungible tokens (Token ID 0) to transfer
    function testFuzzTransferERC20(uint256 amount) public {
        // Bound the transfer amount between 0 and initialMintAmount
        uint256 initialMintAmount = 519_000_000;
        amount = bound(amount, 1000000, initialMintAmount);

        // Perform the transfer to addr1
        contractUnderTest.transfer(addr1, amount);

        // Calculate remaining balance of fungible token (Token ID 0) for the owner
        uint256 expectedFungibleBalance = initialMintAmount - amount;

        // Fetch current balances
        uint256 balFungOwner = contractUnderTest.balanceOf(owner);
        uint256 balOnesOwner = contractUnderTest.balanceOf(owner, 1);
        uint256 balFivesOwner = contractUnderTest.balanceOf(owner, 2);
        uint256 balTwentiesOwner = contractUnderTest.balanceOf(owner, 3);

        uint256 balFungUser = contractUnderTest.balanceOf(addr1);
        uint256 balOnesUser = contractUnderTest.balanceOf(addr1, 1);
        uint256 balFivesUser = contractUnderTest.balanceOf(addr1, 2);
        uint256 balTwentiesUser = contractUnderTest.balanceOf(addr1, 3);

        // Validate balances for owner
        assertEq(balFungOwner, expectedFungibleBalance, "Incorrect fungible balance for owner");
        assertEq(
            balOnesOwner + (balFivesOwner * 5) + (balTwentiesOwner * 20), 
            (initialMintAmount - amount) / (10 ** 6), 
            "Mismatch in total value of fungible and NFT tokens for owner"
        );

        // Validate balances for user
        assertEq(balFungUser, amount, "Incorrect fungible balance for user");
        assertEq(
            balOnesUser + (balFivesUser * 5) + (balTwentiesUser * 20), 
            amount / (10 ** 6), 
            "Mismatch in total value of fungible and NFT tokens for user"
        );
    }

    /// @notice Fuzz test to deploy contract with random cashRanges, transfer random amounts of ERC20 tokens, and validate corresponding NFT balances
    /// @param rangeSize The size of the cashRange (between 1 and 6)
    /// @param amount The amount of fungible tokens (Token ID 0) to transfer
    function testFuzzDynamicCashRangeWhereCashRangesAreMultiples(uint256 rangeSize, uint256 amount) public {
        // Bound the rangeSize between 1 and 6 to ensure it's a valid cashRange size
        rangeSize = bound(rangeSize, 1, 6);
        uint256 initialMintAmount = 10000_000_000;
        // Generate a random cashRange array of length `rangeSize`
        uint256[] memory cashRange = new uint256[](rangeSize);
        uint256 lastValue = 0;
        // Ensure each subsequent value is a multiple of the previous one
        for (uint256 i = 0; i < rangeSize; i++) {
            uint256 multiple = bound(uint256(keccak256(abi.encodePacked(i))), 2, 5); // Random multiplier between 2 and 5
            if (i == 0) {
                cashRange[i] = multiple;
            } else {
                cashRange[i] = cashRange[i - 1] * multiple;
            }
            console.log(cashRange[i]);
        }
        
        // Deploy a new instance of the contract with the generated cashRange
        contractUnderTest = new dn404(
            10000,          // _totalSupply
            "Digital Dollar",
            "USD",
            uris,
            cashRange
        );

        // Bound the transfer amount between 1 million and initialMintAmount
        amount = bound(amount, 1_000_000, initialMintAmount);

        // Perform the transfer to addr1
        contractUnderTest.transfer(addr1, amount);

        // Calculate remaining balance of fungible token (Token ID 0) for the owner
        uint256 expectedFungibleBalance = initialMintAmount - amount;

        // Fetch balances for the owner and user
        uint256 balFungOwner = contractUnderTest.balanceOf(owner);
        uint256[] memory balNFTsOwner = new uint256[](rangeSize);
        uint256 balFungUser = contractUnderTest.balanceOf(addr1);
        uint256[] memory balNFTsUser = new uint256[](rangeSize);

        uint256 totalNFTValueOwner = 0;
        uint256 totalNFTValueUser = 0;

        // Calculate total NFT values for both owner and user
        for (uint256 i = 0; i < rangeSize; i++) {
            balNFTsOwner[i] = contractUnderTest.balanceOf(owner, i + 1);
            balNFTsUser[i] = contractUnderTest.balanceOf(addr1, i + 1);
            totalNFTValueOwner += balNFTsOwner[i] * cashRange[i];
            totalNFTValueUser += balNFTsUser[i] * cashRange[i];
        }
        uint256 remainderOwner = (balFungOwner / (10 ** 6)) % cashRange[0];
        uint256 remainderUser = (balFungUser / (10 ** 6)) % cashRange[0];
        // Validate balances for the owner
        assertEq(balFungOwner, expectedFungibleBalance, "Incorrect fungible balance for owner");
        assertEq(
            totalNFTValueOwner,
            ((initialMintAmount - amount) / (10 ** 6)) - remainderOwner,
            "Mismatch in total value of fungible and NFT tokens for owner"
        );

        // Validate balances for the user
        assertEq(balFungUser, amount, "Incorrect fungible balance for user");
        assertEq(
            totalNFTValueUser,
            (amount / (10 ** 6)) - remainderUser,
            "Mismatch in total value of fungible and NFT tokens for user"
        );
    }

    /// @notice Fuzz test to deploy contract with random cashRanges, transfer random amounts of ERC20 tokens, and validate corresponding NFT balances
    /// @param rangeSize The size of the cashRange (between 1 and 6)
    /// @param amount The amount of fungible tokens (Token ID 0) to transfer
    function testFuzzDynamicCashRangeWhereCashRangesAreNotMultiples(uint256 rangeSize, uint256 amount) public {
        // Bound the rangeSize between 1 and 6 to ensure it's a valid cashRange size
        rangeSize = bound(rangeSize, 1, 6);
        uint256 initialMintAmount = 10000_000_000;
        // Generate a random cashRange array of length `rangeSize`
        uint256[] memory cashRange = new uint256[](rangeSize);
        uint256 lastValue = 0;
        for (uint256 i = 0; i < rangeSize; i++) {
            // Generate a random value greater than the last one to ensure ascending order
            cashRange[i] = lastValue + bound(uint256(keccak256(abi.encodePacked(i))), 1, 100);
            lastValue = cashRange[i];
            console.log(cashRange[i]);
        }
        
        // Deploy a new instance of the contract with the generated cashRange
        contractUnderTest = new dn404(
            10000,          // _totalSupply
            "Digital Dollar",
            "USD",
            uris,
            cashRange
        );

        // Bound the transfer amount between 1 million and initialMintAmount
        amount = bound(amount, 1_000_000, initialMintAmount);

        // Perform the transfer to addr1
        contractUnderTest.transfer(addr1, amount);

        // Calculate remaining balance of fungible token (Token ID 0) for the owner
        uint256 expectedFungibleBalance = initialMintAmount - amount;

        // Fetch balances for the owner and user
        uint256 balFungOwner = contractUnderTest.balanceOf(owner);
        uint256[] memory balNFTsOwner = new uint256[](rangeSize);
        uint256 balFungUser = contractUnderTest.balanceOf(addr1);
        uint256[] memory balNFTsUser = new uint256[](rangeSize);

        uint256 totalNFTValueOwner = 0;
        uint256 totalNFTValueUser = 0;

        // Calculate total NFT values for both owner and user
        for (uint256 i = 0; i < rangeSize; i++) {
            balNFTsOwner[i] = contractUnderTest.balanceOf(owner, i + 1);
            balNFTsUser[i] = contractUnderTest.balanceOf(addr1, i + 1);
            totalNFTValueOwner += balNFTsOwner[i] * cashRange[i];
            totalNFTValueUser += balNFTsUser[i] * cashRange[i];
        }
        uint256 remainderOwner = (balFungOwner / (10 ** 6)) % cashRange[0];
        uint256 remainderUser = (balFungUser / (10 ** 6)) % cashRange[0];
        // Validate balances for the owner
        assertEq(balFungOwner, expectedFungibleBalance, "Incorrect fungible balance for owner");
        require(
            totalNFTValueOwner <= initialMintAmount/ (10 ** 6),
            "Mismatch in total value of fungible and NFT tokens for owner"
        );

        // Validate balances for the user
        assertEq(balFungUser, amount, "Incorrect fungible balance for user");
        require(
            totalNFTValueUser <= amount / (10 ** 6),
            "Mismatch in total value of fungible and NFT tokens for user"
        );
    }

    function testFuzzTransferNFTs(uint256 tokenId, uint256 amount) public {
        // Bound tokenId to ensure it's within the valid range of NFT Token IDs (1 to ranges.length)
        tokenId = bound(tokenId, 1, range.length);
        uint256 initial = 519_000_000;

        // Bound amount to ensure it's within a reasonable range
        uint256 maxNFTBalance = contractUnderTest.balanceOf(owner, tokenId);
        amount = bound(amount, 1, maxNFTBalance);

        // Perform the NFT transfer from the owner to addr1
        contractUnderTest.safeTransferFrom(owner, addr1, tokenId, amount, "");

        // Fetch updated balances for owner and addr1
        uint256 ownerBalance = contractUnderTest.balanceOf(owner, tokenId);
        uint256 addr1Balance = contractUnderTest.balanceOf(addr1, tokenId);

        uint256 ownerBalanceFungible = contractUnderTest.balanceOf(owner);
        uint256 addr1BalanceFungible = contractUnderTest.balanceOf(addr1);

        // Calculate expected balances
        uint256 expectedOwnerBalance = maxNFTBalance - amount;
        uint256 expectedAddr1Balance = amount;

        // Validate balances after transfer
        assertEq(ownerBalance, expectedOwnerBalance, "Incorrect NFT balance for owner after transfer");
        assertEq(addr1Balance, expectedAddr1Balance, "Incorrect NFT balance for user after transfer");
        assertEq(ownerBalanceFungible, initial - ((amount * range[tokenId - 1]) * (10 ** 6)));
        assertEq(addr1BalanceFungible, amount * range[tokenId - 1] * (10 ** 6));
    }

    function testSendWrongTokenId() public {
        vm.expectRevert(dn404.InvalidTokenId.selector);
        contractUnderTest.safeTransferFrom(owner, addr1, 4, 5, "");
    }

    // Test: Should mint 519 * 10**6 ERC20 tokens to the owner (Token ID 0)
    function testMintERC20ToOwner() public {
        uint256 expectedBalance = 519 * 10**6;
        uint256 actualBalance = contractUnderTest.balanceOf(owner);
        assertEq(actualBalance, expectedBalance, "ERC20 mint failed for Token ID 0");
    }

    // Test: Should mint NFTs of Token ID 1 to the owner
    function testMintNFTsTokenID1ToOwner() public {
        uint256 expectedBalance = 4;
        uint256 actualBalance = contractUnderTest.balanceOf(owner, 1);
        assertEq(actualBalance, expectedBalance, "NFT mint failed for Token ID 1");
    }

    // Test: Should mint NFTs of Token ID 2 to the owner
    function testMintNFTsTokenID2ToOwner() public {
        uint256 expectedBalance = 3;
        uint256 actualBalance = contractUnderTest.balanceOf(owner, 2);
        assertEq(actualBalance, expectedBalance, "NFT mint failed for Token ID 2");
    }

    // Test: Should mint NFTs of Token ID 3 to the owner
    function testMintNFTsTokenID3ToOwner() public {
        uint256 expectedBalance = 25;
        uint256 actualBalance = contractUnderTest.balanceOf(owner, 3);
        assertEq(actualBalance, expectedBalance, "NFT mint failed for Token ID 3");
    }

    // Test: Transfer 1.5 Token ID 0 to addr1
    function testTransferFractionalERC20TokenID0() public {
        contractUnderTest.transfer(addr1, 1.5 * 10**6);
        uint256 expectedBalance = 1.5 * 10**6;
        uint256 actualBalance = contractUnderTest.balanceOf(addr1);
        assertEq(actualBalance, expectedBalance, "Transfer of fractional ERC20 failed for Token ID 0");
        
        uint256 expectedNFTBalance = 1;
        uint256 actualNFTBalance = contractUnderTest.balanceOf(addr1, 1);
        assertEq(actualNFTBalance, expectedNFTBalance, "Transfer of fractional ERC20 did not mint Token ID 1");
    }

    // Test: Check the denomination of Token ID 0 for 27 tokens
    function testCheckDenominationOfTokenID0() public {
        contractUnderTest.transfer(addr1, 27 * 10**6);

        // Token ID 0 should have 27 tokens
        uint256 balance0 = contractUnderTest.balanceOf(addr1);
        assertEq(balance0, 27 * 10**6, "ERC20 balance mismatch for Token ID 0");

        // Token ID 1 should have 2 tokens
        uint256 balance1 = contractUnderTest.balanceOf(addr1, 1);
        assertEq(balance1, 2, "NFT balance mismatch for Token ID 1");

        // Token ID 2 should have 1 token
        uint256 balance2 = contractUnderTest.balanceOf(addr1, 2);
        assertEq(balance2, 1, "NFT balance mismatch for Token ID 2");

        // Token ID 3 should have 1 token
        uint256 balance3 = contractUnderTest.balanceOf(addr1, 3);
        assertEq(balance3, 1, "NFT balance mismatch for Token ID 3");
    }

    // Test: Add up ERC20 Token ID 0 and convert to Token ID 1
    function testAddAndConvertERC20ToNFT() public {
        contractUnderTest.transfer(addr1, 0.8 * 10**6);

        uint256 balance0 = contractUnderTest.balanceOf(addr1);
        uint256 balance1 = contractUnderTest.balanceOf(addr1, 1);

        assertEq(balance0, 0.8 * 10**6, "Partial ERC20 transfer failed for Token ID 0");
        assertEq(balance1, 0, "Unexpected balance for Token ID 1");

        // Transfer 0.2 Token ID 0 to addr1
        contractUnderTest.transfer(addr1, 0.2 * 10**6);

        balance0 = contractUnderTest.balanceOf(addr1);
        balance1 = contractUnderTest.balanceOf(addr1, 1);

        assertEq(balance0, 10**6, "ERC20 conversion failed for Token ID 0");
        assertEq(balance1, 1, "Full conversion to Token ID 1 failed");
    }

    // Test: Revert if cashRange is not in ascending order
    function testRevertIfRangeNotAscending() public {
        uint256[] memory invalidRange = new uint256[](5);
        invalidRange[0] = 2;
        invalidRange[1] = 1;
        invalidRange[2] = 5;
        invalidRange[3] = 2;
        invalidRange[4] = 5;

        vm.expectRevert(dn404.InvalidRangeValue.selector);
        new dn404(5190, "Digital Dollar", "USD", uris, invalidRange);
    }

    // Test: Revert if cashRange exceeds limit
    function testRevertIfRangeTooLarge() public {
        uint256[] memory largeRange = new uint256[](7);
        for (uint256 i = 0; i < 7; i++) {
            largeRange[i] = i + 1;
        }

        vm.expectRevert(dn404.ArrayExceedsLimit.selector);
        new dn404(5190, "Digital Dollar", "USD", uris, largeRange);
    }
    
    function test1155BalOfId0returns0() public {
        uint256 bal1155 = contractUnderTest.balanceOf(address(this), 0);
        uint256 balERC20 = contractUnderTest.balanceOf(address(this));

        assertEq(bal1155, 0);
        assertEq(balERC20, 519 * (10 ** 6));
    }

    function testConvertTokens() public {
        uint256[] memory amts = new uint256[](3);
        amts[0] = 519;
        amts[1] = 0;
        amts[2] = 0;
        uint256 erc20Before = contractUnderTest.balanceOf(address(this));
        contractUnderTest.convertTokens(amts, false);

        uint256 bal1 = contractUnderTest.balanceOf(address(this), 1);
        uint256 bal2 = contractUnderTest.balanceOf(address(this), 2);
        uint256 bal3 = contractUnderTest.balanceOf(address(this), 3);
        uint256 balAfter = contractUnderTest.balanceOf(address(this));

        assertEq(bal1, 519);
        assertEq(bal2, 0);
        assertEq(bal3, 0);
        assertEq(erc20Before, balAfter);

    }

    function testConvertTokensRevertBadConversion() public {
        uint256[] memory amts = new uint256[](3);
        amts[0] = 519;
        amts[1] = 4;
        amts[2] = 7;
        uint256 erc20Before = contractUnderTest.balanceOf(address(this));

        vm.expectRevert(dn404.IncorrectConversion.selector);
        contractUnderTest.convertTokens(amts, false);
    }

    function testConvertTokensFuzz(uint256 a1, uint256 a2, uint256 a3) public {
        a1 = bound(uint256(keccak256(abi.encodePacked(uint256(1)))), 1, 519);
        a2 = bound(uint256(keccak256(abi.encodePacked(uint256(2)))), 1, (519 - a1) / 5);
        a3 = bound(uint256(keccak256(abi.encodePacked(uint256(3)))), 1, (519 - a1 - (a2 * 5)) / 20);
        uint256[] memory amts = new uint256[](3);
        amts[0] = a1;
        amts[1] = a2;
        amts[2] = a3;
        uint256 erc20Before = contractUnderTest.balanceOf(address(this));
        contractUnderTest.convertTokens(amts, false);

        uint256 bal1 = contractUnderTest.balanceOf(address(this), 1);
        uint256 bal2 = contractUnderTest.balanceOf(address(this), 2);
        uint256 bal3 = contractUnderTest.balanceOf(address(this), 3);
        uint256 balAfter = contractUnderTest.balanceOf(address(this));

        assertEq(bal1, a1);
        assertEq(bal2, a2);
        assertEq(bal3, a3);
        assertEq(erc20Before, balAfter);

    }

    function testConvertTokensAndTransferFuzz(uint256 a1, uint256 a2, uint256 a3, uint256 amt) public {
        a1 = bound(uint256(keccak256(abi.encodePacked(uint256(1)))), 1, 519);
        a2 = bound(uint256(keccak256(abi.encodePacked(uint256(2)))), 1, (519 - a1) / 5);
        a3 = bound(uint256(keccak256(abi.encodePacked(uint256(3)))), 1, (519 - a1 - (a2 * 5)) / 20);
        uint256[] memory amts = new uint256[](3);
        amts[0] = a1;
        amts[1] = a2;
        amts[2] = a3;
        uint256 erc20Before = contractUnderTest.balanceOf(address(this));
        contractUnderTest.convertTokens(amts, false);

        uint256 bal1 = contractUnderTest.balanceOf(address(this), 1);
        uint256 bal2 = contractUnderTest.balanceOf(address(this), 2);
        uint256 bal3 = contractUnderTest.balanceOf(address(this), 3);
        uint256 balAfter = contractUnderTest.balanceOf(address(this));

        assertEq(bal1, a1);
        assertEq(bal2, a2);
        assertEq(bal3, a3);
        assertEq(erc20Before, balAfter);

        amt = bound(uint256(keccak256(abi.encodePacked(uint256(1)))), 1, 519000000);
        contractUnderTest.transfer(addr1, amt);

        balAfter = contractUnderTest.balanceOf(address(this));
        bal1 = contractUnderTest.balanceOf(address(this), 1);
        bal2 = contractUnderTest.balanceOf(address(this), 2);
        bal3 = contractUnderTest.balanceOf(address(this), 3);
        uint256 expectedFung = 519000000 - amt;
        uint256 convertedFung = expectedFung / (10 ** 6);
        uint256 expected3 = convertedFung / 20;
        uint256 expected2 = (convertedFung - (expected3 * 20)) / 5;
        uint256 expected1 = (convertedFung - (expected3 * 20) - (expected2 * 5));

        assertEq(bal1, expected1);
        assertEq(bal2, expected2);
        assertEq(bal3, expected3);
        assertEq(balAfter, expectedFung);

    }

    function testConvertTokensAndLockFuzz(uint256 a1, uint256 a2, uint256 a3, uint256 amt) public {
        contractUnderTest.transfer(addr1, 200 * (10 ** 6));

        a1 = bound(uint256(keccak256(abi.encodePacked(uint256(1)))), 1, 319);
        a2 = bound(uint256(keccak256(abi.encodePacked(uint256(2)))), 1, (319 - a1) / 5);
        a3 = bound(uint256(keccak256(abi.encodePacked(uint256(3)))), 1, (319 - a1 - (a2 * 5)) / 20);
        amt = bound(amt, 0, 200);
        uint256[] memory amts = new uint256[](3);
        amts[0] = a1;
        amts[1] = a2;
        amts[2] = a3;
        uint256 erc20Before = contractUnderTest.balanceOf(address(this));
        contractUnderTest.convertTokens(amts, true);

        uint256 bal1 = contractUnderTest.balanceOf(address(this), 1);
        uint256 bal2 = contractUnderTest.balanceOf(address(this), 2);
        uint256 bal3 = contractUnderTest.balanceOf(address(this), 3);
        uint256 balAfter = contractUnderTest.balanceOf(address(this));

        assertEq(bal1, a1);
        assertEq(bal2, a2);
        assertEq(bal3, a3);
        assertEq(erc20Before, balAfter);

        erc20Before = contractUnderTest.balanceOf(address(this));
        vm.prank(addr1);
        contractUnderTest.transfer(address(this), amt * (10 ** 6));

        bal1 = contractUnderTest.balanceOf(address(this), 1);
        bal2 = contractUnderTest.balanceOf(address(this), 2);
        bal3 = contractUnderTest.balanceOf(address(this), 3);
        balAfter = contractUnderTest.balanceOf(address(this));

        assertEq(bal1, a1);
        assertEq(bal2, a2);
        assertEq(bal3, a3);
        assertEq(erc20Before + amt * (10 ** 6), balAfter);

    }
}
