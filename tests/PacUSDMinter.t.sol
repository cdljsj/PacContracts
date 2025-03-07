// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PacUSDMinter} from "../src/PacUSDMinter.sol";
import {PacUSD} from "../src/PacUSD.sol";
import {ERC20Wrapper} from "../src/ERC20Wrapper.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockSupraPriceFeeds} from "./mocks/MockSupraPriceFeeds.sol";

contract PacUSDMinterTest is Test {
    PacUSDMinter public minter;
    PacUSD public pacUsd;
    ERC20Wrapper public pacMMFWrapper;
    MockERC20 public pacMMF;
    MockSupraPriceFeeds public priceFeeds;

    address public alice = makeAddr("alice");
    bytes32 public constant PAIR_ID = bytes32("MMF/USD");
    uint256 public constant INITIAL_BALANCE = 1000e18;
    uint256 public constant BASE_PRICE = 1e8; // $1.00 with 8 decimals

    function setUp() public {
        // Deploy mock contracts
        pacMMF = new MockERC20("PAC MMF", "MMF", 18);
        priceFeeds = new MockSupraPriceFeeds();

        // Deploy wrapper
        pacMMFWrapper = new ERC20Wrapper(
            IERC20(address(pacMMF)),
            "Wrapped PAC MMF",
            "wMMF"
        );

        // Deploy PacUSD
        pacUsd = new PacUSD(
            address(pacMMFWrapper),
            address(priceFeeds),
            PAIR_ID
        );

        // Deploy minter
        minter = new PacUSDMinter(
            address(pacMMF),
            address(pacMMFWrapper),
            address(pacUsd)
        );

        // Setup initial state
        priceFeeds.setPrice(BASE_PRICE);
        pacMMF.mint(alice, INITIAL_BALANCE);

        vm.startPrank(alice);
        pacMMF.approve(address(minter), type(uint256).max);
        pacMMFWrapper.approve(address(pacUsd), type(uint256).max);
        vm.stopPrank();
    }

    function test_WrapAndMint() public {
        uint256 amount = 100e18;
        
        vm.startPrank(alice);
        minter.wrapAndMint(amount);
        vm.stopPrank();

        // Check final state
        // Calculate expected PacUSD amount
        uint256 expectedPacUsdAmount = pacUsd.calculateMintAmount(amount);

        // Check MMF balances
        assertEq(pacMMF.balanceOf(alice), INITIAL_BALANCE - amount, "Wrong user MMF balance");

        // Check wrapped token balances
        assertEq(pacMMFWrapper.balanceOf(address(pacUsd)), amount, "Wrong PacUSD wrapper balance");

        // Check PacUSD balance
        assertEq(pacUsd.balanceOf(alice), expectedPacUsdAmount, "Wrong user PacUSD balance");
    }

    function test_RevertZeroAmount() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        minter.wrapAndMint(0);
        vm.stopPrank();
    }

    function testFuzz_WrapAndMint(uint256 amount) public {
        // Bound amount to reasonable values
        amount = bound(amount, 1e18, 1000e18);

        vm.startPrank(alice);
        minter.wrapAndMint(amount);
        vm.stopPrank();

        // Check balances
        // Calculate expected PacUSD amount
        uint256 expectedPacUsdAmount = pacUsd.calculateMintAmount(amount);

        // Check MMF balances
        assertEq(pacMMF.balanceOf(alice), INITIAL_BALANCE - amount, "Wrong user MMF balance");
        assertEq(pacMMF.balanceOf(address(pacMMFWrapper)), amount, "Wrong wrapper MMF balance");

        // Check wrapped token balances
        assertEq(pacMMFWrapper.balanceOf(address(pacUsd)), amount, "Wrong PacUSD wrapper balance");

        // Check PacUSD balance
        assertEq(pacUsd.balanceOf(alice), expectedPacUsdAmount, "Wrong user PacUSD balance");
    }
}
