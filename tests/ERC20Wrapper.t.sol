// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {ERC20Wrapper} from "../src/ERC20Wrapper.sol";

contract ERC20WrapperTest is Test {
    MockERC20 public underlying;
    ERC20Wrapper public wrapper;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    uint256 public constant INITIAL_BALANCE = 1000e18;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    function setUp() public {
        // Deploy mock token and wrapper
        underlying = new MockERC20("Mock Token", "MOCK", 18);
        wrapper = new ERC20Wrapper(underlying, "Wrapped Token", "wTKN");

        // Mint some tokens to alice
        underlying.mint(alice, INITIAL_BALANCE);

        // Approve wrapper contract
        vm.prank(alice);
        underlying.approve(address(wrapper), type(uint256).max);
        
        vm.prank(bob);
        underlying.approve(address(wrapper), type(uint256).max);
    }

    function test_Deployment() public view {
        assertEq(wrapper.name(), "Wrapped Token");
        assertEq(wrapper.symbol(), "wTKN");
        assertEq(wrapper.decimals(), underlying.decimals());
        assertEq(address(wrapper.underlyingToken()), address(underlying));
    }

    function test_Deposit() public {
        uint256 amount = 100e18;
        
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, amount);
        wrapper.deposit(amount);

        assertEq(wrapper.balanceOf(alice), amount);
        assertEq(underlying.balanceOf(alice), INITIAL_BALANCE - amount);
        assertEq(underlying.balanceOf(address(wrapper)), amount);
    }

    function test_DepositFor() public {
        uint256 amount = 100e18;
        
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, amount);
        wrapper.depositFor(alice, bob, amount);

        assertEq(wrapper.balanceOf(bob), amount);
        assertEq(underlying.balanceOf(alice), INITIAL_BALANCE - amount);
        assertEq(underlying.balanceOf(address(wrapper)), amount);
    }

    function test_Withdraw() public {
        uint256 depositAmount = 100e18;
        uint256 withdrawAmount = 60e18;
        
        // First deposit
        vm.prank(alice);
        wrapper.deposit(depositAmount);

        // Then withdraw
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Withdraw(alice, withdrawAmount);
        wrapper.withdraw(withdrawAmount);

        assertEq(wrapper.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(underlying.balanceOf(alice), INITIAL_BALANCE - depositAmount + withdrawAmount);
        assertEq(underlying.balanceOf(address(wrapper)), depositAmount - withdrawAmount);
    }

    function test_WithdrawTo() public {
        uint256 depositAmount = 100e18;
        uint256 withdrawAmount = 60e18;
        
        // First deposit
        vm.prank(alice);
        wrapper.deposit(depositAmount);

        // Then withdraw to bob
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Withdraw(bob, withdrawAmount);
        wrapper.withdrawTo(bob, withdrawAmount);

        assertEq(wrapper.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(underlying.balanceOf(alice), INITIAL_BALANCE - depositAmount);
        assertEq(underlying.balanceOf(bob), withdrawAmount);
        assertEq(underlying.balanceOf(address(wrapper)), depositAmount - withdrawAmount);
    }

    function test_RevertZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(ERC20Wrapper.ZeroAmount.selector);
        wrapper.deposit(0);

        vm.prank(alice);
        vm.expectRevert(ERC20Wrapper.ZeroAmount.selector);
        wrapper.withdraw(0);
    }

    function test_RevertInsufficientBalance() public {
        uint256 depositAmount = 100e18;
        
        vm.prank(alice);
        wrapper.deposit(depositAmount);

        vm.prank(alice);
        vm.expectRevert(ERC20Wrapper.InsufficientBalance.selector);
        wrapper.withdraw(depositAmount + 1);
    }

    function test_UnderlyingBalance() public {
        uint256 amount = 100e18;
        
        vm.prank(alice);
        wrapper.deposit(amount);

        assertEq(wrapper.underlyingBalance(), amount);
    }
}
