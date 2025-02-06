# SLICE404: A Fusion of ERC20 and ERC1155 for Hybrid Fungible and NFT Assets

## Introduction

SLICE404 introduces a novel category of crypto asset, combining the properties of ERC20 and ERC1155 tokens to allow dual functionality: it can be used and traded as either a fungible token or as a non-fungible token (NFT). By leveraging the ERC1155 multi-token standard, SLICE404 addresses gas inefficiencies and limitations associated with other hybrid token standards, specifically those based on ERC721. Through this dual-function protocol, SLICE404 offers flexibility for users who want to transfer or sell their assets either as fungible tokens on a decentralized exchange or as NFTs on a marketplace.

The following document delves into the structure, functionality, and design of SLICE404, providing smart contract developers and tokenomics enthusiasts with a comprehensive understanding of this experimental token standard.

## Core Structure of SLICE404

### ERC1155 Foundation

SLICE404 is primarily built upon the ERC1155 standard, which allows the creation and management of both fungible and non-fungible tokens within the same contract. This structure enables SLICE404 to use multiple token IDs, where each token ID can have unique properties. The unique characteristics of SLICE404 are defined by two categories of token IDs:

- **Token ID 0:** Acts as the fungible token component, compatible with ERC20 standard functions.
- **Token IDs 1-6:** Act as non-fungible token (NFT) "bills" that represent fixed denominations of SLICE and can be traded on NFT marketplaces.

#### Token ID 0: The ERC20 Component

Token ID 0 is reserved for fungible operations and strictly adheres to the ERC20 standard, including functions such as `transfer`, `approve`, and `transferFrom`. These ERC20 functions apply only to token ID 0, allowing users to interact with SLICE as a typical fungible token.

To prevent Token ID 0 from appearing on NFT marketplaces, any ERC1155 balance inquiries for Token ID 0 return zero. This ensures SLICE404 behaves consistently with ERC20 standards while still allowing selective visibility of fungible assets on NFT platforms.

#### Token IDs 1-6: The NFT Component

SLICE404 extends its utility by implementing Token IDs 1-6 as NFTs, each representing fixed denominations of SLICE. These token IDs function as "bills," allowing users to hold and trade SLICE in a tangible, divisible manner similar to fiat currency.

The denominations in SLICE404 are as follows:

- **Token ID 1:** 1 SLICE bill
- **Token ID 2:** 5 SLICE bill
- **Token ID 3:** 10 SLICE bill
- **Token ID 4:** 20 SLICE bill
- **Token ID 5:** 50 SLICE bill
- **Token ID 6:** 100 SLICE bill

These bills offer users a choice: they can either hold SLICE as a fungible asset (Token ID 0) or convert it into denominations represented by Token IDs 1-6 for trading on NFT marketplaces. The token balances across these IDs are dynamically adjusted to reflect users' total SLICE holdings.

## Optimized Token Transfers and Gas Efficiency

SLICE404 addresses the gas inefficiencies associated with transferring large quantities of hybrid fungible/NFT assets in previous standards, such as ERC404 tokens that fuse ERC20 with ERC721. In those designs, each whole token transferred requires minting a new ERC721 token ID, causing gas costs to scale linearly. SLICE404 circumvents this limitation by leveraging ERC1155’s fixed token IDs, significantly reducing gas consumption during transactions.

## Automated Denomination Adjustment

By default, SLICE404 dynamically updates users' NFT "bill" holdings to reflect their fungible token balance. Upon any fungible token transfer, SLICE404 rebalances the user’s NFT bills to the most efficient distribution. For instance, if a user with a 10 SLICE balance (represented by a single 10 SLICE bill) transfers 3 SLICE, their NFT balance will adjust to reflect a 5 SLICE bill and two 1 SLICE bills.

This automated denomination adjustment ensures efficient bill management without requiring user intervention, minimizing fragmentation of holdings.

## Manual Bill Customization and Locking

While SLICE404’s default behavior optimizes for efficient denomination, users can choose to customize their bill composition. A function allows users to “break” bills into any desired denomination combination, provided they possess sufficient fungible tokens. For example, a user with 10 SLICE can split their holdings into ten 1 SLICE bills instead of a single 10 SLICE bill.

Additionally, users can lock their current bill configuration to prevent automatic adjustment on future transfers. However, locked bills will not automatically update when additional SLICE is acquired; users must manually distribute new tokens into the appropriate denominations if their bills are locked.

## Deployment and Customization Options

SLICE404 is designed as an open-source protocol that other projects can deploy and customize to suit their needs. Key customization options include:

- **Number of Denominations:** Projects can specify up to six unique denominations.
- **Token Values for Denominations:** Projects can define custom values for each denomination, provided each subsequent denomination value is strictly greater than the previous. Although the protocol enforces this increasing sequence rule, it is strongly recommended that each denomination be a multiple of the first to avoid unexpected behavior.

SLICE404’s flexibility allows projects to adapt the protocol to different economic models, offering a wide range of possibilities for developers to explore new applications in DeFi, gaming, and NFT marketplaces.

## Standard Functions and Methods

### ERC20 Functions for Token ID 0

For compatibility with existing DeFi infrastructure, SLICE404 implements standard ERC20 functions for Token ID 0. Key functions include:

- `balanceOf(address owner)`: Returns the fungible SLICE balance for Token ID 0.
- `transfer(address to, uint256 amount)`: Transfers SLICE from one address to another.
- `approve(address spender, uint256 amount)`: Grants permission to spend a specified amount of SLICE on behalf of the owner.
- `transferFrom(address from, address to, uint256 amount)`: Facilitates SLICE transfers on behalf of the owner.

### ERC1155 Functions for Token IDs 1-6

The ERC1155 interface allows users to manage the NFT components (Token IDs 1-6) of SLICE404. Relevant functions include:

- `balanceOf(address account, uint256 id)`: Returns the number of SLICE “bills” held by the account for a given token ID (excluding ID 0).
- `safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data)`: Facilitates transfers of NFT bills between accounts.
- `safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data)`: Enables batch transfers of multiple NFT bills in a single transaction.

These ERC1155 functions enable users to manage their SLICE holdings in both fungible and non-fungible forms, providing flexibility across multiple transaction methods.

## Conclusion

SLICE404 establishes a new paradigm in token design by combining ERC20 and ERC1155 into a single, cohesive protocol. By balancing fungible and non-fungible properties, SLICE404 offers a versatile asset that can be easily transferred on decentralized exchanges or listed as an NFT on marketplaces. The protocol’s efficient gas structure, dynamic denomination adjustment, and customization options make SLICE404 a powerful tool for projects seeking innovative solutions in tokenomics.

As an experimental open-source standard, SLICE404 invites developers and tokenomics enthusiasts to explore its potential, adapt it to new use cases, and contribute to the evolution of crypto asset design. With SLICE404, the boundary between fungible and non-fungible assets becomes more fluid, opening the door to hybrid assets that can function seamlessly in a diverse and rapidly evolving digital economy.