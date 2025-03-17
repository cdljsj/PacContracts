// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import { Script } from "forge-std/src/Script.sol";
import { console } from "forge-std/src/console.sol";
import { MockERC20 } from "../tests/mocks/MockERC20.sol";
import { BaseScript } from "./Base.s.sol";

/// @dev Script to deploy MockERC20 token to Sepolia testnet
contract DeployMockERC20 is BaseScript {
    function run() public broadcast returns (address tokenAddress) {
        // Token parameters - can be customized or read from environment variables
        string memory name;
        string memory symbol;
        uint8 decimals;
        
        // Check if environment variables exist, otherwise use defaults
        try vm.envString("TOKEN_NAME") returns (string memory value) {
            name = value;
        } catch {
            name = "Mock Token";
        }
        
        try vm.envString("TOKEN_SYMBOL") returns (string memory value) {
            symbol = value;
        } catch {
            symbol = "MTK";
        }
        
        try vm.envUint("TOKEN_DECIMALS") returns (uint256 value) {
            decimals = uint8(value);
        } catch {
            decimals = 18;
        }
        
        // Deploy the MockERC20 token
        MockERC20 token = new MockERC20(name, symbol, decimals);
        tokenAddress = address(token);
        
        // Optional: Mint some tokens to the deployer
        uint256 initialMint;
        try vm.envUint("INITIAL_MINT") returns (uint256 value) {
            initialMint = value;
        } catch {
            initialMint = 1000000 * 10**decimals; // Default: 1 million tokens
        }
        if (initialMint > 0) {
            token.mint(broadcaster, initialMint);
        }
        
        // Log deployment information
        console.log("MockERC20 token deployed to Sepolia:");
        console.log("Token Address:", tokenAddress);
        console.log("Name:", name);
        console.log("Symbol:", symbol);
        console.log("Decimals:", decimals);
        if (initialMint > 0) {
            console.log("Initial supply minted to:", broadcaster);
            console.log("Initial mint amount:", initialMint);
        }
    }
}
