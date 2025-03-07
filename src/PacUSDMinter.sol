// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PacUSD} from "./PacUSD.sol";
import {ERC20Wrapper} from "./ERC20Wrapper.sol";

/**
 * @title PacUSDMinter
 * @notice A utility contract that helps users wrap their pacMMF tokens and mint PacUSD in one transaction
 */
contract PacUSDMinter is ReentrancyGuard {
    // Immutable state variables
    IERC20 public immutable pacMMF;
    ERC20Wrapper public immutable pacMMFWrapper;
    PacUSD public immutable pacUsd;

    // Custom errors
    error ZeroAmount();
    error TransferFailed();
    error ApprovalFailed();

    // Events
    event OneStepMint(
        address indexed user,
        uint256 pacMMFAmount,
        uint256 wrappedAmount,
        uint256 pacUsdAmount
    );

    constructor(
        address _pacMMF,
        address _pacMMFWrapper,
        address _pacUsd
    ) {
        pacMMF = IERC20(_pacMMF);
        pacMMFWrapper = ERC20Wrapper(_pacMMFWrapper);
        pacUsd = PacUSD(_pacUsd);

        // Approve PacUSD to spend wrapped tokens
        if (!pacMMFWrapper.approve(address(pacUsd), type(uint256).max)) {
            revert ApprovalFailed();
        }
    }

    /**
     * @notice Wrap pacMMF tokens and mint PacUSD in one transaction
     * @param amount Amount of pacMMF tokens to wrap and use as collateral
     */
    function wrapAndMint(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        // 1. Transfer pacMMF from user to this contract
        if (!pacMMF.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }

        // 2. Approve pacMMFWrapper to spend pacMMF
        if (!pacMMF.approve(address(pacMMFWrapper), amount)) {
            revert ApprovalFailed();
        }

        // 3. Deposit pacMMF to get wrapped tokens
        // Note: depositFor will transfer pacMMF from this contract to pacMMFWrapper
        // and mint wrapped tokens to this contract
        pacMMFWrapper.deposit(amount);

        // 4. Approve PacUSD to spend wrapped tokens
        if (!pacMMFWrapper.approve(address(pacUsd), amount)) {
            revert ApprovalFailed();
        }

        // 5. Mint PacUSD tokens to this contract
        // Note: PacUSD.mint will transfer wrapped tokens from this contract to PacUSD
        uint256 mintAmount = pacUsd.mint(amount);

        // 6. Transfer PacUSD to user
        if (!pacUsd.transfer(msg.sender, mintAmount)) {
            revert TransferFailed();
        }

        emit OneStepMint(msg.sender, amount, amount, mintAmount);
    }
}
