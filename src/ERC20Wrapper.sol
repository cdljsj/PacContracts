// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title ERC20Wrapper
 * @dev A wrapper for ERC20 tokens that adds additional functionality like batch operations
 * and permit support
 */
contract ERC20Wrapper is ERC20Permit, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable underlyingToken;
    uint8 private immutable _underlyingDecimals;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    error ZeroAmount();
    error InsufficientBalance();

    constructor(
        IERC20 _underlyingToken,
        string memory name,
        string memory symbol
    )
        ERC20(name, symbol)
        ERC20Permit(name)
    {
        underlyingToken = _underlyingToken;
        _underlyingDecimals = ERC20(address(_underlyingToken)).decimals();
    }

    /**
     * @notice Get the decimals of the wrapper token
     * @return The number of decimals of the wrapper token (same as underlying)
     */
    function decimals() public view override returns (uint8) {
        return _underlyingDecimals;
    }

    /**
     * @notice Deposit underlying tokens and mint wrapped tokens
     * @param amount Amount of tokens to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        _deposit(msg.sender, msg.sender, amount);
    }

    /**
     * @notice Deposit underlying tokens on behalf of another address
     * @param from Address from which to transfer underlying tokens
     * @param to Address to mint wrapped tokens to
     * @param amount Amount of tokens to deposit
     */
    function depositFor(address from, address to, uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        _deposit(from, to, amount);
    }

    /**
     * @notice Burn wrapped tokens and withdraw underlying tokens
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        _withdraw(msg.sender, msg.sender, amount);
    }

    /**
     * @notice Withdraw underlying tokens to a different address
     * @param to Address to receive underlying tokens
     * @param amount Amount of tokens to withdraw
     */
    function withdrawTo(address to, uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        _withdraw(msg.sender, to, amount);
    }

    /**
     * @notice Get the balance of underlying tokens in the contract
     */
    function underlyingBalance() external view returns (uint256) {
        return underlyingToken.balanceOf(address(this));
    }

    /**
     * @dev Internal function to handle deposits
     */
    function _deposit(address from, address to, uint256 amount) internal {
        underlyingToken.safeTransferFrom(from, address(this), amount);
        _mint(to, amount);

        emit Deposit(from, amount);
    }

    /**
     * @dev Internal function to handle withdrawals
     */
    function _withdraw(address from, address to, uint256 amount) internal {
        if (balanceOf(from) < amount) revert InsufficientBalance();

        _burn(from, amount);
        underlyingToken.safeTransfer(to, amount);

        emit Withdraw(to, amount);
    }
}
