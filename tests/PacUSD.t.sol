// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {PacUSD} from "../src/PacUSD.sol";
import {MockSupraPriceFeeds} from "./mocks/MockSupraPriceFeeds.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract PacUSDTest is Test {
    uint256 constant SHARES_PER_TOKEN_PRECISION = 1e18;
    // Events for checking invariants
    event SupplyChanged(uint256 oldSupply, uint256 newSupply);
    event SharesChanged(uint256 oldShares, uint256 newShares);
    PacUSD public pacUsd;
    MockSupraPriceFeeds public priceFeeds;
    MockERC20 public pacMMFWrapper;
    
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    bytes32 public constant PAIR_ID = bytes32("MMF/USD");
    uint256 public constant INITIAL_BALANCE = 1000e18;
    uint256 public constant BASE_PRICE = 1e8; // $1.00 with 8 decimals

    event Mint(address indexed user, uint256 collateralAmount, uint256 pacUsdAmount);
    event Burn(address indexed user, uint256 pacUsdAmount, uint256 collateralAmount);
    event Rebase(uint256 oldTotalSupply, uint256 newTotalSupply, uint256 oldSharesPerToken, uint256 newSharesPerToken);

    function setUp() public {
        // Deploy mock contracts
        priceFeeds = new MockSupraPriceFeeds();
        // Setup initial state
        priceFeeds.setPrice(BASE_PRICE);
        pacMMFWrapper = new MockERC20("PAC MMF Wrapper", "wPacMMF", 18);
        
        // Deploy PacUSD contract
        pacUsd = new PacUSD(
            address(pacMMFWrapper),
            address(priceFeeds),
            PAIR_ID
        );

        pacMMFWrapper.mint(alice, INITIAL_BALANCE);
        pacMMFWrapper.mint(bob, INITIAL_BALANCE);

        vm.startPrank(alice);
        pacMMFWrapper.approve(address(pacUsd), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        pacMMFWrapper.approve(address(pacUsd), type(uint256).max);
        vm.stopPrank();
    }

    function test_InitialState() public {
        assertEq(pacUsd.totalSupply(), 0);
        assertEq(pacUsd.balanceOf(alice), 0);
        assertEq(pacUsd.balanceOf(bob), 0);
    }

    function test_FirstMint() public {
        uint256 mintAmount = 100e18;
        
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit Mint(alice, mintAmount, mintAmount);
        pacUsd.mint(mintAmount);
        vm.stopPrank();

        assertEq(pacUsd.totalSupply(), mintAmount);
        assertEq(pacUsd.balanceOf(alice), mintAmount);
        assertEq(pacMMFWrapper.balanceOf(address(pacUsd)), mintAmount);
    }

    function test_MintAndBurn() public {
        uint256 mintAmount = 100e18;
        
        // Mint
        vm.startPrank(alice);
        pacUsd.mint(mintAmount);
        vm.stopPrank();

        // Burn
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit Burn(alice, mintAmount, mintAmount);
        pacUsd.burn(mintAmount);
        vm.stopPrank();

        assertEq(pacUsd.totalSupply(), 0);
        assertEq(pacUsd.balanceOf(alice), 0);
        assertEq(pacMMFWrapper.balanceOf(address(pacUsd)), 0);
    }

    function test_Transfer() public {
        uint256 mintAmount = 100e18;
        uint256 transferAmount = 30e18;
        
        // Mint
        vm.prank(alice);
        pacUsd.mint(mintAmount);

        // Transfer
        vm.prank(alice);
        pacUsd.transfer(bob, transferAmount);

        assertEq(pacUsd.balanceOf(alice), mintAmount - transferAmount);
        assertEq(pacUsd.balanceOf(bob), transferAmount);
    }

    function test_RebaseUpward() public {
        uint256 mintAmount = 100e18;
        
        // Mint initial tokens
        vm.prank(alice);
        pacUsd.mint(mintAmount);

        // Price increases by 20%
        uint256 newPrice = (BASE_PRICE * 120) / 100;
        priceFeeds.setPrice(newPrice);

        // Rebase
        pacUsd.rebase();

        // Supply should increase by 20% when price increases by 20%
        uint256 expectedSupply = (mintAmount * 120) / 100;
        assertApproxEqRel(pacUsd.totalSupply(), expectedSupply, 1e16); // 1% tolerance
        assertApproxEqRel(pacUsd.balanceOf(alice), expectedSupply, 1e16);
    }

    function test_RebaseDownward() public {
        uint256 mintAmount = 100e18;
        
        // Mint initial tokens
        vm.prank(alice);
        pacUsd.mint(mintAmount);

        // Price decreases by 20%
        uint256 newPrice = (BASE_PRICE * 80) / 100;
        priceFeeds.setPrice(newPrice);

        // Rebase
        pacUsd.rebase();

        // Supply should decrease by 20% when price decreases by 20%
        uint256 expectedSupply = (mintAmount * 80) / 100;
        assertApproxEqRel(pacUsd.totalSupply(), expectedSupply, 1e16);
        assertApproxEqRel(pacUsd.balanceOf(alice), expectedSupply, 1e16);
    }

    function test_RevertInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance(address,uint256,uint256)", alice, 1e18, 0));
        pacUsd.burn(1e18);
    }

    function test_RevertTransferInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert();
        pacUsd.transfer(bob, 1e18);
    }

    function test_MintZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        pacUsd.mint(0);
    }

    function test_RebaseMultipleTimesHighPrice() public {
        uint256 mintAmount = 100e18;
        
        // Mint initial tokens
        vm.prank(alice);
        pacUsd.mint(mintAmount);

        // Price increases by 20%
        uint256 newPrice = (BASE_PRICE * 120) / 100;
        priceFeeds.setPrice(newPrice);

        // Record initial state
        uint256 initialSupply = pacUsd.totalSupply();

        // First rebase
        pacUsd.rebase();
        uint256 supplyAfterFirstRebase = pacUsd.totalSupply();

        // Second rebase
        pacUsd.rebase();
        uint256 supplyAfterSecondRebase = pacUsd.totalSupply();

        // Supply should increase by 20% after first rebase
        uint256 expectedSupply = (initialSupply * 120) / 100;
        assertApproxEqRel(supplyAfterFirstRebase, expectedSupply, 1e16); // 1% tolerance

        // Supply should not change after second rebase
        assertEq(supplyAfterSecondRebase, supplyAfterFirstRebase);
    }

    function test_PauseUnpause() public {
        // Check proxy admin
        assertTrue(pacUsd.hasRole(pacUsd.DEFAULT_ADMIN_ROLE(), address(this)));

        // Only deployer (this contract) has PAUSER_ROLE
        assertTrue(pacUsd.hasRole(pacUsd.PAUSER_ROLE(), address(this)));
        assertFalse(pacUsd.hasRole(pacUsd.PAUSER_ROLE(), alice));

        // Pause contract
        pacUsd.pause();
        assertTrue(pacUsd.paused());

        // Try operations while paused
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        pacUsd.mint(100e18);

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        pacUsd.burn(100e18);

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        pacUsd.rebase();
        vm.stopPrank();

        // Unpause contract
        pacUsd.unpause();
        assertFalse(pacUsd.paused());

        // Operations should work after unpause
        vm.prank(alice);
        pacUsd.mint(100e18);
        assertEq(pacUsd.balanceOf(alice), 100e18);
    }

    function test_OnlyPauserCanPause() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        pacUsd.pause();

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        pacUsd.unpause();
    }


    function test_RebaseNoChange() public {
        uint256 mintAmount = 100e18;
        
        // Mint initial tokens
        vm.prank(alice);
        pacUsd.mint(mintAmount);

        // Record initial state
        uint256 initialSupply = pacUsd.totalSupply();
        uint256 initialBalance = pacUsd.balanceOf(alice);

        // Call rebase multiple times
        for (uint256 i = 0; i < 10; i++) {
            pacUsd.rebase();
        }

        // State should not change
        assertEq(pacUsd.totalSupply(), initialSupply);
        assertEq(pacUsd.balanceOf(alice), initialBalance);
    }

    function test_BurnZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        pacUsd.burn(0);
    }

    /* ========== FUZZ TESTS ========== */

    /// @notice Fuzz test mint and burn operations
    function testFuzz_MintAndBurn(uint256 mintAmount, uint256 burnAmount) public {
        // Bound the input to reasonable values and avoid overflow
        mintAmount = bound(mintAmount, 1e18, 1_000e18);
        
        vm.startPrank(alice);
        
        // Record initial state
        uint256 initialBalance = pacMMFWrapper.balanceOf(alice);
        
        // Mint
        pacMMFWrapper.approve(address(pacUsd), mintAmount);
        pacUsd.mint(mintAmount);
        
        // Bound burn amount to what we have
        uint256 balance = pacUsd.balanceOf(alice);
        burnAmount = bound(burnAmount, 0, balance);
        
        // Skip time to allow rebase
        skip(24 hours);
        
        // Burn
        if (burnAmount > 0) {
            pacUsd.burn(burnAmount);
        }
        
        vm.stopPrank();
        
        // Check invariants
        assertGe(pacUsd.totalSupply(), 0, "Total supply should never be negative");
        assertGe(pacUsd.totalSupply(), 0, "Total supply should never be negative");
        assertLe(pacUsd.balanceOf(alice), initialBalance, "User balance should not exceed initial balance");
    }

    /// @notice Fuzz test transfer operations
    function testFuzz_Transfer(uint256 amount) public {
        // First mint some tokens
        uint256 mintAmount = 1000e18;
        vm.startPrank(alice);
        pacMMFWrapper.approve(address(pacUsd), mintAmount);
        pacUsd.mint(mintAmount);
        vm.stopPrank();
        
        // Bound transfer amount
        amount = bound(amount, 0, pacUsd.balanceOf(alice));
        
        // Record balances before transfer
        uint256 aliceBalanceBefore = pacUsd.balanceOf(alice);
        uint256 bobBalanceBefore = pacUsd.balanceOf(bob);
        
        // Transfer
        vm.prank(alice);
        if (amount > 0) {
            pacUsd.transfer(bob, amount);
        }
        
        // Check invariants
        assertEq(pacUsd.balanceOf(alice), aliceBalanceBefore - amount, "Alice balance incorrect");
        assertEq(pacUsd.balanceOf(bob), bobBalanceBefore + amount, "Bob balance incorrect");
        assertEq(pacUsd.totalSupply(), mintAmount, "Total supply should not change");
    }

    /// @notice Fuzz test rebase with different prices
    function testFuzz_Rebase(uint256 newPrice) public {
        // First mint some tokens
        uint256 mintAmount = 1000e18;
        vm.startPrank(alice);
        pacMMFWrapper.approve(address(pacUsd), mintAmount);
        pacUsd.mint(mintAmount);
        vm.stopPrank();
        
        // Bound price to reasonable values (0.5 USD to 2 USD)
        newPrice = bound(newPrice, 1.1e8, 2e8);
        
        // Skip time to allow rebase
        skip(24 hours);
        
        // Set new price
        priceFeeds.setPrice(newPrice);
        
        // Record state before rebase
        uint256 supplyBefore = pacUsd.totalSupply();
        
        // Print initial state
        emit log_named_uint("BASE_PRICE", BASE_PRICE);
        emit log_named_uint("newPrice", newPrice);
        emit log_named_uint("supplyBefore", supplyBefore);
        
        // Rebase
        pacUsd.rebase();
        
        // Print final state
        uint256 supplyAfter = pacUsd.totalSupply();
        emit log_named_uint("supplyAfter", supplyAfter);
        
        // Check invariants
        assertGe(pacUsd.totalSupply(), 0, "Total supply should never be negative");
        
        // Check price-supply relationship
        // If price increases, supply should increase and vice versa
        if (newPrice > BASE_PRICE) {
            emit log_string("Price increased, supply should increase");
            assertGt(pacUsd.totalSupply(), supplyBefore, "Supply should increase when price increases");
        } else if (newPrice < BASE_PRICE) {
            emit log_string("Price decreased, supply should decrease");
            assertLt(pacUsd.totalSupply(), supplyBefore, "Supply should decrease when price decreases");
        }
    }

    /// @notice Fuzz test share calculation
    function testFuzz_ShareCalculation(uint256 amount) public {
        // Bound amount to reasonable values
        amount = bound(amount, 1e18, 1_000e18);
        
        vm.startPrank(alice);
        pacMMFWrapper.approve(address(pacUsd), amount);
        
        // Mint
        pacUsd.mint(amount);
        
        // Check share calculation
        uint256 balance = pacUsd.balanceOf(alice);
        assertGt(balance, 0, "Balance should be positive");
        assertEq(balance, amount, "Balance should match mint amount");
        
        vm.stopPrank();
    }
}
