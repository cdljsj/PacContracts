// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/src/Script.sol";
import { console } from "forge-std/src/console.sol";
import { BaseScript } from "./Base.s.sol";
import { UpgradeableOFTAdapter } from "../src/UpgradeableOFTAdapter.sol";
import { UpgradeableOFT } from "../src/UpgradeableOFT.sol";

/// @dev Script to configure cross-chain functionality between UpgradeableOFTAdapter and UpgradeableOFT
contract ConfigureCrossChainOFT is BaseScript {
    function run() public broadcast {
        // Load contract addresses from environment variables
        address ethereumContract = vm.envAddress("ETHEREUM_CONTRACT_ADDRESS");
        address baseContract = vm.envAddress("BASE_CONTRACT_ADDRESS");

        // Configure Ethereum Sepolia -> Base Sepolia
        configureEthereumToBase(ethereumContract, baseContract);

        // Configure Base Sepolia -> Ethereum Sepolia
        configureBaseToEthereum(baseContract, ethereumContract);

        console.log("Cross-chain configuration completed successfully!");
    }

    function configureEthereumToBase(address ethereumContract, address baseContract) internal {
        console.log("Configuring Ethereum Sepolia -> Base Sepolia");
        console.log("Ethereum Contract:", ethereumContract);
        console.log("Base Contract:", baseContract);

        // 使用合约地址直接调用

        // Set peer for Base Sepolia using V2 interface
        bytes32 baseContractAddress = bytes32(uint256(uint160(baseContract)));

        // Call the setPeer method directly on the adapter
        (bool success,) = ethereumContract.call(
            abi.encodeWithSignature("setPeer(uint32,bytes32)", BASE_SEPOLIA_CHAIN_ID, baseContractAddress)
        );
        require(success, "Failed to set peer on Ethereum contract");

        console.log("Peer set for Ethereum Sepolia -> Base Sepolia");
    }

    function configureBaseToEthereum(address baseContract, address ethereumContract) internal {
        console.log("Configuring Base Sepolia -> Ethereum Sepolia");
        console.log("Base Contract:", baseContract);
        console.log("Ethereum Contract:", ethereumContract);

        // 使用合约地址直接调用

        // Set peer for Ethereum Sepolia using V2 interface
        bytes32 ethereumContractAddress = bytes32(uint256(uint160(ethereumContract)));

        // Call the setPeer method directly on the OFT
        (bool success,) = baseContract.call(
            abi.encodeWithSignature("setPeer(uint32,bytes32)", ETHEREUM_SEPOLIA_CHAIN_ID, ethereumContractAddress)
        );
        require(success, "Failed to set peer on Base contract");

        console.log("Peer set for Base Sepolia -> Ethereum Sepolia");
    }
}
