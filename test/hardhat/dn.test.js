const { expect } = require("chai");
const { ethers } = require("hardhat");
const {Typed, formatEther} = require("ethers");

describe("DN444 Contract - Current Behavior", function () {
  let dn404, owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2, _] = await ethers.getSigners();
    
    const DN404 = await ethers.getContractFactory("dn404"); // Correct contract factory name
    const range = [1, 5, 20];
    dn404 = await DN404.deploy(
      5190,            
      "Digital Dollar",
      "USD",           
      ["uri1", "uri2", "uri3", "uri4", "uri5", "uri6"], // _uri array
      range
    );

});


    // * Static
    // ? Changing the BeforeEach will change the values of the following tests
    // Test: Should Mint 1000 ERC 20 Tokens to the Owner
    it("should mint ERC20 of Token ID 0 to the owner", async function () {
        expect(await dn404.balanceOf(Typed.address(owner.address), Typed.uint(0))).to.equal(519 * 10 ** 6);
        }
    );

    // Test Should Mint NFTs Token ID 1 to the Owner
    it("should mint NFTs of Token ID 3 to the owner", async function () {
        expect(await dn404.balanceOf(Typed.address(owner.address), Typed.uint(3))).to.equal(25);
        }
    );
    it("should mint NFTs of Token ID 2 to the owner", async function () {
        expect(await dn404.balanceOf(Typed.address(owner.address), Typed.uint(2))).to.equal(3);
        }
    );
    it("should mint NFTs of Token ID 1 to the owner", async function () {
        expect(await dn404.balanceOf(Typed.address(owner.address), Typed.uint(1))).to.equal(4);
        }
    );

    // * Transfers
    // Test: When the user transfers 1 and a half ID 0 tokens to another user
    // ? Check the balance of the receiver for Token ID 0 and 1
    it("should transfer a fractional ERC20 amount of Token ID 0", async function () {
        await dn404.transfer(addr1.address, 1.5 * 10 ** 6); // Transfer 1.5 tokens
        // ERC 20 Token ID 0
        expect(await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(0))).to.equal(1.5 * 10 ** 6);

        // NFT Token ID 1
        expect(await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(1))).to.equal(1);
        
    });

    // Check the Denomination of the Token ID 0
    it("should check the denomination of Token ID 0 into Largest first", async function () {
        // Transfer 27 tokens
        // Since, 1$ = 1 * 10 ** 6
        // 5$ = 5 * 10 ** 6
        // 20$ = 20 * 10 ** 6
        // 27$ should be 20$ + 5$ + 1$ + 1$
        await dn404.transfer(addr1.address, 27 * 10 ** 6);

        // Check the Balance of receiver for all IDs
        // Token ID 0 should have 27 tokens
        expect(await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(0))).to.equal(27 * 10 ** 6);
        // Token ID 1 should have 2 tokens
        expect(await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(1))).to.equal(2);
        // Token ID 2 should have 1 token
        expect(await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(2))).to.equal(1);
        // Token ID 3 should have 1 token
        expect(await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(3))).to.equal(1);

    });

    it("should add up ERC20 Token ID 0 and convert to Token ID 1", async function () {
        // Balance of Owner Before
        const tokenId0Owner = await dn404.balanceOf(Typed.address(owner.address), Typed.uint(0));
        const tokenId1Owner = await dn404.balanceOf(Typed.address(owner.address), Typed.uint(1));
        const tokenId2Owner = await dn404.balanceOf(Typed.address(owner.address), Typed.uint(2));
        const tokenId3Owner = await dn404.balanceOf(Typed.address(owner.address), Typed.uint(3));
    

        // Transfer 0.8 Token ID 0 to addr1
        await dn404.transfer(addr1.address, 0.8 * 10 ** 6);
        
        let addr1ID0 = await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(0));
        let addr1ID1 = await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(1));
    

        expect(addr1ID0).to.equal(0.8 * 10 ** 6);
        expect(addr1ID1).to.equal(0);
        
        // Transfer 0.2 Token ID 0 to addr1
        await dn404.transfer(addr1.address, 0.2 * 10 ** 6);
        
        addr1ID0 = await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(0));
        addr1ID1 = await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(1));
    

        expect(addr1ID0).to.equal(10 ** 6); // Ensure full conversion works appropriately
        
         // Balance of Owner Verifications
         const finalTokenId2Owner = await dn404.balanceOf(Typed.address(owner.address), Typed.uint(2));
         expect(finalTokenId2Owner).to.equal(tokenId2Owner);
    
         const finalTokenId3Owner = await dn404.balanceOf(Typed.address(owner.address), Typed.uint(3));
         expect(finalTokenId3Owner).to.equal(tokenId3Owner);
     });
    
    
    

    // Convert TokenID 3 to TokenID 1
    it("should Convert TokenID 3 to TokenID 1", async function () {
        // Transfer 5 Token ID 1 to addr1
        // await dn404.transfer(addr1.address, 5 * 10 ** 6, Typed.uint(1));
        // expect(await dn404.balanceOf(Typed.address(addr1.address), Typed.uint(1))).to.equal(5);
    
        const tokenID1Owner = BigInt(await dn404.balanceOf(owner.address, Typed.uint(1)));
        const tokenID2Owner = BigInt(await dn404.balanceOf(owner.address, Typed.uint(2)));
        const tokenID3Owner = BigInt(await dn404.balanceOf(owner.address, Typed.uint(3)));
        
        // Convert TokenID 3 to TokenID 1
        await dn404.convertToken(1, Typed.uint(3), Typed.uint(1));

        // Check the Balances after conversion
        const tokenID1OwnerAfter = BigInt(await dn404.balanceOf(owner.address, Typed.uint(1)));
        const tokenID2OwnerAfter = BigInt(await dn404.balanceOf(owner.address, Typed.uint(2)));
        const tokenID3OwnerAfter = BigInt(await dn404.balanceOf(owner.address, Typed.uint(3)));
    
        // Expected results after conversion:
        const expectedTokenID1Balance = tokenID1Owner + BigInt(20); // Conversion rate: 20 units of Token ID 1 for 1 unit of Token ID 3
        const expectedTokenID2Balance = tokenID2Owner; // Should remain the same
        const expectedTokenID3Balance = tokenID3Owner - BigInt(1); // Minus one unit of Token ID 3
    
        expect(tokenID1OwnerAfter).to.equal(expectedTokenID1Balance);
        expect(tokenID2OwnerAfter).to.equal(expectedTokenID2Balance);
        expect(tokenID3OwnerAfter).to.equal(expectedTokenID3Balance);
    });

    it("should revert if ranges out of order", async () => {
        const DN404 = await ethers.getContractFactory("dn404"); // Correct contract factory name
        const range = [2, 1, 5, 2, 5];
        await expect(DN404.deploy(
            5190,            
            "Digital Dollar",
            "USD",           
            ["uri1", "uri2", "uri3", "uri4", "uri5", "uri6"], // _uri array
            range
        )).to.be.revertedWithCustomError(dn404, "InvalidRangeValue");

    })

    it("should revert if range too large", async () => {
        const DN404 = await ethers.getContractFactory("dn404"); // Correct contract factory name
        const range = [1, 2, 3, 4, 5, 6, 7];
        await expect(DN404.deploy(
            5190,            
            "Digital Dollar",
            "USD",           
            ["uri1", "uri2", "uri3", "uri4", "uri5", "uri6"], // _uri array
            range
        )).to.be.revertedWithCustomError(dn404, "ArrayExceedsLimit");

    })

});
