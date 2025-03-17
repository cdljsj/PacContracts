// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

// Script import removed as it's not used
import { console } from "forge-std/src/console.sol";
import { ERC20Wrapper } from "../src/ERC20Wrapper.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { BaseScript } from "./Base.s.sol";

/// @dev Script to deploy ERC20Wrapper for a previously deployed ERC20 token
contract DeployERC20Wrapper is BaseScript {
    function run() public broadcast returns (address wrapperAddress) {
        // Get the underlying token address from environment variable
        address underlyingTokenAddress;
        try vm.envAddress("UNDERLYING_TOKEN_ADDRESS") returns (address addr) {
            underlyingTokenAddress = addr;
        } catch {
            revert("UNDERLYING_TOKEN_ADDRESS environment variable not set");
        }

        // Get wrapper token name and symbol from environment variables or use defaults
        string memory wrapperName;
        try vm.envString("WRAPPER_NAME") returns (string memory name) {
            wrapperName = name;
        } catch {
            // Default: add "Wrapped " prefix to the underlying token name
            // Note: This might fail if the underlying token doesn't implement the name() function
            try ERC20(underlyingTokenAddress).name() returns (string memory tokenName) {
                wrapperName = string(abi.encodePacked("Wrapped ", tokenName));
            } catch {
                wrapperName = "Wrapped Token";
            }
        }

        string memory wrapperSymbol;
        try vm.envString("WRAPPER_SYMBOL") returns (string memory symbol) {
            wrapperSymbol = symbol;
        } catch {
            // Default: add "w" prefix to the underlying token symbol
            try ERC20(underlyingTokenAddress).symbol() returns (string memory symbol) {
                wrapperSymbol = string(abi.encodePacked("w", symbol));
            } catch {
                wrapperSymbol = "wTKN";
            }
        }

        // Deploy the ERC20Wrapper contract
        ERC20Wrapper wrapper = new ERC20Wrapper(IERC20(underlyingTokenAddress), wrapperName, wrapperSymbol);
        wrapperAddress = address(wrapper);

        // Log deployment information
        console.log("ERC20Wrapper deployed to Sepolia:");
        console.log("Wrapper Address:", wrapperAddress);
        console.log("Underlying Token:", underlyingTokenAddress);
        console.log("Wrapper Name:", wrapperName);
        console.log("Wrapper Symbol:", wrapperSymbol);

        // Optional: Deposit some tokens into the wrapper if specified
        uint256 initialDeposit;
        try vm.envUint("INITIAL_DEPOSIT") returns (uint256 amount) {
            initialDeposit = amount;
        } catch {
            initialDeposit = 0;
        }

        if (initialDeposit > 0) {
            // Check if the deployer has approved the wrapper to spend tokens
            IERC20 underlyingToken = IERC20(underlyingTokenAddress);
            uint256 allowance = underlyingToken.allowance(broadcaster, wrapperAddress);

            if (allowance < initialDeposit) {
                console.log("Note: To deposit tokens, you need to approve the wrapper contract first.");
                console.log("Run this command to approve:");
                console.log("cast send", underlyingTokenAddress, "approve(address,uint256)");
                console.log("with parameters:", wrapperAddress, initialDeposit);
                console.log("from address:", broadcaster);
            } else {
                // Attempt to deposit tokens
                try wrapper.deposit(initialDeposit) {
                    console.log("Successfully deposited tokens into the wrapper:");
                    console.log("Amount:", initialDeposit);
                } catch {
                    console.log("Failed to deposit tokens. Make sure you have sufficient balance.");
                }
            }
        }

        return wrapperAddress;
    }
}
