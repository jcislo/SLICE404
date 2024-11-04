// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "./ERC1155Custom.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title dn404
 * @dev A contract that combines ERC1155 and ERC20 functionality with custom logic.
 * Inherits from ERC1155Custom, IERC20Errors, and Ownable.
 */
contract dn404 is ERC1155Custom, IERC20Errors, Ownable {
    error CannotTransfer();
    error CannotTransferMix();
    error ArrayExceedsLimit();
    error InvalidRangeValue();
    error InvalidArrayLength();
    error InvalidTokenId();
    error OverflowRisk();
    error InsufficientBalance();
    error InsufficientBalanceForUpdate();
    error InsufficientERC20Balance();
    error UnsafeMath();
    error IncorrectConversion();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event LockAssigned(address user, bool isLock);

    mapping(address => bool) public exempt;
    mapping(address => bool) public isAssignLock;
    mapping(address account => mapping(address spender => uint256))
        private _allowances;
    mapping(uint256 => string) public metaData;
    uint256 private immutable _totalSupply;
    uint256 public constant decimals = 6;
    string private _name;
    string private _symbol;

    uint256[] public cashRange;

    /**
     * @dev Constructor to initialize the dn404 contract with initial settings.
     * @param _totalSupply_ The total supply of the ERC20 token.
     * @param name_ The name of the ERC20 token.
     * @param symbol_ The symbol of the ERC20 token.
     * @param _uri An array of metadata URIs for the ERC1155 tokens.
     * @param ranges An array representing the cash range denominations.
     */
    constructor(
        uint256 _totalSupply_,
        string memory name_,
        string memory symbol_,
        string[] memory _uri,
        uint256[] memory ranges
    ) ERC1155Custom("") Ownable(msg.sender) {
        require(ranges.length <= 6, ArrayExceedsLimit());
        uint256 value;
        for (uint8 i; i < ranges.length; i++) {
            require(ranges[i] > value, InvalidRangeValue());
            value = ranges[i];
            cashRange.push(ranges[i]);
        }
        _mint(msg.sender, 0, _totalSupply_ * (10 ** decimals), "");
        // * Setting the total supply
        _totalSupply = _totalSupply_ * (10 ** decimals);
        _name = name_;
        _symbol = symbol_;
        exempt[address(0)] = true;
        addURI(_uri);
    }

    /**
     * @dev Adds metadata URIs to the contract.
     * @param _uri An array of metadata URIs to be added.
     */
    function addURI(string[] memory _uri) internal {
        for (uint256 i; i < _uri.length; i++) {
            metaData[i] = _uri[i];
        }
    }

    /**
     * @notice Marks an address as exempt from minting restrictions.
     * @param toAdd The address to be marked as exempt.
     */
    function exemptFromMint(address toAdd) external {
        exempt[toAdd] = true;
    }

    /**
     * @notice Returns the metadata URI for a given token ID.
     * @param id The ID of the token.
     * @return The metadata URI of the token.
     */
    function uri(uint256 id) public view override returns (string memory) {
        return metaData[id];
    }

    // ERC20 functions

    /**
     * @notice Returns the name of the ERC20 token.
     * @return The name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the ERC20 token.
     * @return The symbol of the token.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the total supply of the ERC20 token.
     * @return The total supply of the token.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns the balance of a given address.
     * @param account The address of the account.
     * @return The balance of the account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[0][account];
    }

    /**
     * @notice Transfers tokens from the caller to another address.
     * @param to The recipient address.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer was successful.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        safeTransferFrom(msg.sender, to, 0, value, "");
        return true;
    }

    /**
     * @notice Returns the allowance of a spender for a given owner.
     * @param owner The owner of the tokens.
     * @param spender The spender allowed to spend tokens.
     * @return The allowance of the spender.
     */
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approves a spender to spend a certain amount of tokens.
     * @param spender The spender's address.
     * @param value The amount of tokens to approve.
     * @return True if the approval was successful.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @notice Transfers tokens from one address to another.
     * @param from The sender's address.
     * @param to The recipient's address.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer was successful.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        _spendAllowance(from, msg.sender, value);
        safeTransferFrom(from, to, 0, value, "");
        return true;
    }

    /**
     * @dev Spends the allowance of a spender for a given owner.
     * Reverts if the allowance is insufficient.
     * @param owner The owner of the tokens.
     * @param spender The spender of the tokens.
     * @param value The amount to spend.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(
                    spender,
                    currentAllowance,
                    value
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Approves a spender to spend tokens on behalf of the owner.
     * @param owner The owner's address.
     * @param spender The spender's address.
     * @param value The amount of tokens to approve.
     * @param emitEvent Whether to emit an approval event.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates balances during token transfers.
     * Handles both ERC1155 and ERC20 transfer logic.
     * @param from The sender's address.
     * @param to The recipient's address.
     * @param ids An array of token IDs to transfer.
     * @param values An array of token amounts to transfer.
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override {
        require(ids.length == values.length, InvalidArrayLength());

        // Cannot batchTransfer tokenID 0 with other tokenIDs
        bool isERC20;
        for (uint256 k = 0; k < ids.length; ++k) {
            if (ids[k] == 0) {
                require(
                    ids.length == 1,
                    CannotTransferMix()
                );
                isERC20 = true;
                break;
            }
        }

        if (!isERC20) {
            uint256 toSendERC20;
            for (uint256 i = 0; i < ids.length; ++i) {
                
                toSendERC20 += getCorrespondingERC20Value(ids[i], values[i]);
                updateBalance(to, from, ids[i], values[i]);
                
            }
            require(_balances[0][from] >= toSendERC20, InsufficientERC20Balance());
            _balances[0][from] -= toSendERC20;
            _balances[0][to] += toSendERC20;
            emit Transfer(from, to, toSendERC20);
        } else {
            uint256 value = values[0];

            // Sender's Balance Update
            if (from != address(0)) {
                updateERC20Balance(from, -int256(value));
            }

            // Receiver's Balance Update
            if (to != address(0)) {
                updateERC20Balance(to, int256(value));
            }

            emit Transfer(from, to, value);
        }
    }

    /**
     * @dev Converts a given ERC1155 token ID and value to the corresponding ERC20 value.
     * Reverts if the ID is invalid or if there is an overflow risk.
     * @param id The ID of the ERC1155 token.
     * @param value The amount of the ERC1155 token.
     * @return The corresponding ERC20 value.
     */
    function getCorrespondingERC20Value(
        uint256 id,
        uint256 value
    ) internal view returns (uint256) {
        require(
            value <= type(uint256).max / (10 ** decimals),
            OverflowRisk()
        );
        require(id > 0 && id <= cashRange.length, InvalidTokenId());

        return value * cashRange[id - 1] * (10 ** decimals);

    }

    /**
     * @dev Updates balances during an ERC1155 transfer.
     * Reverts if the sender's balance is insufficient.
     * @param to The recipient's address.
     * @param from The sender's address.
     * @param id The ID of the token.
     * @param value The amount of the token.
     */
    function updateBalance(
        address to,
        address from,
        uint256 id,
        uint256 value
        
    ) internal {
        require(
            _balances[id][from] >= value,
            InsufficientBalanceForUpdate()
        );

        _balances[id][from] -= value;
        _balances[id][to] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    /**
     * @dev Updates the ERC20 balance of a user.
     * Reverts if the user has an insufficient balance.
     * @param user The user's address.
     * @param erc20ValueChange The change in ERC20 balance.
     */
    function updateERC20Balance(
        address user,
        int256 erc20ValueChange
    ) internal {
        unchecked {
            uint256 oldBalance = _balances[0][user];

            if (erc20ValueChange < 0) {
                require(
                    oldBalance >= uint256(-erc20ValueChange),
                    InsufficientERC20Balance()
                );
            }

            uint256 newBalance = addSafe(oldBalance, erc20ValueChange);

            _balances[0][user] = newBalance;
            if (erc20ValueChange < 0 || !isAssignLock[user]) {
                assignCash(user, newBalance);
            }
            
        }
    }  

    /**
     * @dev Safely adds an integer to a uint256, handling overflow and underflow.
     * @param a The uint256 value.
     * @param b The integer value to add.
     * @return c The resulting uint256 value.
     */
    function addSafe(uint256 a, int256 b) internal pure returns (uint256 c) {
        unchecked {
            if (b >= 0) {
                return a + uint(b);
            } else {
                require(a >= uint(-b), UnsafeMath());
                return a - uint(-b);
            }
        }
    }

    /**
     * @dev Assigns ERC1155 tokens based on the user's ERC20 balance.
     * Converts the balance of Token ID 0 into whole dollar amounts.
     * @param user The user's address.
     * @param balance The new ERC20 balance.
     */
    function assignCash(address user, uint256 balance) internal {
        // Convert balance of Token ID 0 into whole dollars based on decimals
        uint256 factor = 10 ** decimals;

        // Guard against overflow on multiplication
        require(
            balance <= type(uint).max / factor,
            OverflowRisk()
        );

        uint256 cash = balance / factor;

        // Quickly return if user is exempt from this process
        if (exempt[user]) return;

        // Track whether any balance has changed
        bool balanceChanged = false;
        uint256[] memory range = cashRange;
        // Assigns as per cashRange from highest to lowest
        for (uint i = range.length; i > 0; i--) {
            uint256 idx = i - 1;

            // Calculate number of tokens to be assigned for current denomination
            uint256 divide = cash / range[idx];

            uint256 oldBalance = _balances[i][user];

            if (oldBalance != divide) {
                _balances[i][user] = divide;
                balanceChanged = true;

                if (oldBalance > divide) {
                    emit TransferSingle(
                        msg.sender,
                        user,
                        address(0),
                        i,
                        oldBalance - divide
                    );
                } else {
                    emit TransferSingle(
                        msg.sender,
                        address(0),
                        user,
                        i,
                        divide - oldBalance
                    );
                }

                // emit LogAssignCash(user, i, oldBalance, divide); // Logging for debug
            }

            unchecked {
                cash -= divide * range[idx];
            }
            
        }

    }

    /**
     * @notice Converts ERC1155 tokens into ERC20 tokens based on the given amounts.
     * Reverts if the input array length is incorrect or if conversion fails.
     * @param amounts An array representing the amounts of each ERC1155 token type.
     */
    function convertTokens(uint256[] calldata amounts, bool isLock) external {
        uint256[] memory range = cashRange;
        require(amounts.length == range.length, InvalidArrayLength());
        
        uint256 totalTokenValue;
        for(uint256 i; i < range.length; i++) {
            totalTokenValue += range[i] * amounts[i];
            uint256 id = i+1;
            uint256 oldBalance = _balances[id][msg.sender];
            _balances[id][msg.sender] = amounts[i];
            if (oldBalance > amounts[i]) {
                emit TransferSingle(
                    msg.sender,
                    msg.sender,
                    address(0),
                    id,
                    oldBalance - amounts[i]
                );
            } else if (oldBalance < amounts[i]) {
                emit TransferSingle(
                    msg.sender,
                    address(0),
                    msg.sender,
                    id,
                    amounts[i] - oldBalance
                );
            }
        }
        uint256 originalBalance = balanceOf(msg.sender) / (10 ** decimals);
        require(originalBalance >= totalTokenValue, IncorrectConversion());
        
        if (isLock != isAssignLock[msg.sender]) {
            _setAssignLock(msg.sender, isLock);
        }
    }

    function setAssignLock(bool isLock) external {
        _setAssignLock(msg.sender, isLock);
    }

    function _setAssignLock(address user, bool isLock) internal {
        isAssignLock[user] = isLock;
        emit LockAssigned(user, isLock);
    }

}

// Current issues:

// 1. Vulnerable to re-assignment attack: if someone assigns their own bills, someone else can 
// send 1 base-unit (0.000001 token) which would trigger the bills to be reassigned. Need a gas efficient
// solution here. Potentially an optional "lock" system where user blocks altering of bills (except transferring).
// If they receive additional ERC20, this would not mint new bills until they reassign or disable the "lock" (not great solution).
// The more expensive the asset, the less likely this is to happen. Could also reduce decimals of the ERC20

// 2. For safety, cashRange values should be multiples of the initial value (first item in array). This is to prevent
// any unexpected calculations errors. Risk here is low. Not currently implemented.
