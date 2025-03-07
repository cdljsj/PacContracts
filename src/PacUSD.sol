// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISupraPriceFeeds } from "./interfaces/ISupraPriceFeeds.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PacUSD Stablecoin
 * @notice A rebasing stablecoin that maintains its peg through wrapper token collateral
 */
contract PacUSD is ERC20Permit, ReentrancyGuard, Pausable, AccessControl {
    // Custom Errors
    error ZeroAmount();
    error InsufficientBalance(address user, uint256 required, uint256 available);
    error InsufficientCollateral(uint256 required, uint256 available);

    error ShareCalculationOverflow(uint256 amount, uint256 sharesPerToken);
    error TransferFailed();
    error NotAuthorized();

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // State variables
    IERC20 public immutable pacMMFWrapper; // The wrapped MMF token used as collateral
    ISupraPriceFeeds public immutable priceFeeds; // Supra price oracle
    bytes32 public immutable pairId; // Supra pair ID for price feed

    uint256 public constant PRICE_DECIMALS = 8; // Supra price feed decimals

    uint256 private _sharesPerToken;
    uint256 private _lastRebasePrice; // Last price when rebase was called
    uint256 private constant SHARES_PER_TOKEN_PRECISION = 1e27; // Base shares unit per token, large enough for
        // precision but small enough to prevent overflow

    // Events
    event Mint(address indexed user, uint256 collateralAmount, uint256 pacUsdAmount);
    event Burn(address indexed user, uint256 pacUsdAmount, uint256 collateralAmount);
    event Rebase(uint256 oldTotalSupply, uint256 newTotalSupply, uint256 oldSharesPerToken, uint256 newSharesPerToken);

    // Internal accounting
    mapping(address => uint256) private _shares;
    uint256 private _totalSupply;
    uint256 private _totalShares;

    constructor(
        address _pacMMF,
        address _priceFeeds,
        bytes32 _pairId
    )
        ERC20("PAC USD Stablecoin", "PacUSD")
        ERC20Permit("PAC USD Stablecoin")
    {
        pacMMFWrapper = IERC20(_pacMMF);
        priceFeeds = ISupraPriceFeeds(_priceFeeds);
        pairId = _pairId;
        _totalSupply = 0;
        _totalShares = 0; // Initial total shares should also be 0
        _sharesPerToken = SHARES_PER_TOKEN_PRECISION; // This value will be recalculated on first mint
        _lastRebasePrice = getPacMMFPrice(); // Use actual initial price

        // Setup access control
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @notice Get the current price of pacMMF in USD from Supra oracle
     * @return price The current price with 8 decimals
     */
    function getPacMMFPrice() public view returns (uint256) {
        return priceFeeds.checkPrice(pairId);
    }

    /**
     * @notice Calculate the amount of PacUSD to mint based on collateral amount
     * @param collateralAmount Amount of pacMMF to deposit
     * @return The amount of PacUSD to mint
     */
    function calculateMintAmount(uint256 collateralAmount) public view returns (uint256) {
        uint256 price = getPacMMFPrice();
        // price has 8 decimals, collateralAmount has 18 decimals
        // result should have 18 decimals
        return (collateralAmount * price) / (10 ** PRICE_DECIMALS);
    }

    /**
     * @notice Calculate the amount of collateral to return based on PacUSD amount
     * @param pacUsdAmount Amount of PacUSD to burn
     * @return The amount of collateral to return
     */
    function calculateCollateralAmount(uint256 pacUsdAmount) public view returns (uint256) {
        uint256 price = getPacMMFPrice();
        // Reverse of mint calculation
        return (pacUsdAmount * (10 ** PRICE_DECIMALS)) / price;
    }

    /**
     * @notice Mint PacUSD by depositing pacMMF
     * @param collateralAmount Amount of pacMMF to deposit
     */
    function mint(uint256 collateralAmount) external nonReentrant whenNotPaused returns (uint256) {
        if (collateralAmount == 0) revert ZeroAmount();

        uint256 mintAmount = calculateMintAmount(collateralAmount);
        if (mintAmount == 0) revert ZeroAmount();

        // Transfer collateral first
        if (!pacMMFWrapper.transferFrom(msg.sender, address(this), collateralAmount)) revert TransferFailed();

        // Mint PacUSD using internal shares
        uint256 shareAmount = mintAmount * _sharesPerToken;
        if (shareAmount / _sharesPerToken != mintAmount) {
            revert ShareCalculationOverflow(mintAmount, _sharesPerToken);
        }
        _totalShares += shareAmount;
        _shares[msg.sender] += shareAmount;
        _totalSupply += mintAmount;

        emit Mint(msg.sender, collateralAmount, mintAmount);
        emit Transfer(address(0), msg.sender, mintAmount);

        return mintAmount;
    }

    /**
     * @notice Burn PacUSD to receive pacMMF
     * @param pacUsdAmount Amount of PacUSD to burn
     */
    function burn(uint256 pacUsdAmount) external nonReentrant whenNotPaused {
        if (pacUsdAmount == 0) revert ZeroAmount();
        uint256 userBalance = balanceOf(msg.sender);
        if (userBalance < pacUsdAmount) {
            revert InsufficientBalance(msg.sender, pacUsdAmount, userBalance);
        }

        uint256 collateralAmount = calculateCollateralAmount(pacUsdAmount);
        if (collateralAmount == 0) revert ZeroAmount();
        uint256 contractBalance = pacMMFWrapper.balanceOf(address(this));
        if (contractBalance < collateralAmount) {
            revert InsufficientCollateral(collateralAmount, contractBalance);
        }

        // Burn PacUSD using internal shares
        uint256 shareAmount = (pacUsdAmount * _sharesPerToken);
        if (shareAmount / _sharesPerToken != pacUsdAmount) {
            revert ShareCalculationOverflow(pacUsdAmount, _sharesPerToken);
        }
        _shares[msg.sender] -= shareAmount;
        _totalSupply -= pacUsdAmount;

        // Transfer collateral
        if (!pacMMFWrapper.transfer(msg.sender, collateralAmount)) revert TransferFailed();

        emit Burn(msg.sender, pacUsdAmount, collateralAmount);
        emit Transfer(msg.sender, address(0), pacUsdAmount);
    }

    /**
     * @notice Perform rebase operation to maintain the peg
     */
    function rebase() external whenNotPaused {
        uint256 currentPrice = getPacMMFPrice();
        // Check if price is zero
        if (currentPrice == 0) return;

        // If total supply is zero, update price and return
        if (_totalSupply == 0) {
            _lastRebasePrice = currentPrice;
            return;
        }

        // Check if last price is zero
        if (_lastRebasePrice == 0) {
            _lastRebasePrice = currentPrice;
            return;
        }

        uint256 oldTotalSupply = _totalSupply;

        // If price has changed since last rebase, calculate new total supply
        if (currentPrice != _lastRebasePrice) {
            // Calculate the percentage change in price
            // For example, if price increased from 1.0 to 1.2 USD, we need to increase supply by 20%
            // If price decreased from 1.0 to 0.8 USD, we need to decrease supply by 20%
            uint256 newTotalSupply = (oldTotalSupply * currentPrice) / _lastRebasePrice;

            // Only update if the new supply is different (accounting for rounding)
            if (newTotalSupply != oldTotalSupply) {
                uint256 oldSharesPerToken = _sharesPerToken;
                _totalSupply = newTotalSupply;
                _sharesPerToken = _totalShares / _totalSupply;

                emit Rebase(oldTotalSupply, newTotalSupply, oldSharesPerToken, _sharesPerToken);
            }

            // Update last rebase price
            _lastRebasePrice = currentPrice;
        }
    }

    // Override ERC20 functions to use gons for internal accounting
    function balanceOf(address account) public view override returns (uint256) {
        return _shares[account] / _sharesPerToken;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 shareAmount = (amount * _sharesPerToken);
        require(shareAmount / _sharesPerToken == amount, "Share calculation overflow");
        _shares[msg.sender] -= shareAmount;
        _shares[to] += shareAmount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 shareAmount = (amount * _sharesPerToken);
        require(shareAmount / _sharesPerToken == amount, "Share calculation overflow");
        uint256 currentAllowance = allowance(from, msg.sender);
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _shares[from] -= shareAmount;
        _shares[to] += shareAmount;
        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Pause all token operations
     * @dev Only addresses with PAUSER_ROLE can call this function
     */
    function pause() external {
        if (!hasRole(PAUSER_ROLE, msg.sender)) revert NotAuthorized();
        _pause();
    }

    /**
     * @notice Unpause all token operations
     * @dev Only addresses with PAUSER_ROLE can call this function
     */
    function unpause() external {
        if (!hasRole(PAUSER_ROLE, msg.sender)) revert NotAuthorized();
        _unpause();
    }
}
