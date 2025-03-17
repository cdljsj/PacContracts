// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/src/Script.sol";
import { console } from "forge-std/src/console.sol";
import { BaseScript } from "./Base.s.sol";
import { UpgradeableOFTAdapter } from "../src/UpgradeableOFTAdapter.sol";
import { UpgradeableOFT } from "../src/UpgradeableOFT.sol";

/// @dev Script to configure cross-chain functionality between UpgradeableOFTAdapter on Ethereum and UpgradeableOFT on
/// Arbitrum
contract ConfigureCrossChainArbitrum is BaseScript {
    function run() public broadcast {
        address ethereumContract = vm.envAddress("ETHEREUM_CONTRACT_ADDRESS");
        address arbitrumContract = vm.envAddress("ARBITRUM_CONTRACT_ADDRESS");

        // Configure Ethereum -> Arbitrum
        configureEthereumToArbitrum(ethereumContract, arbitrumContract);

        // Configure Arbitrum -> Ethereum
        configureArbitrumToEthereum(arbitrumContract, ethereumContract);
    }

    function configureEthereumToArbitrum(address ethereumContract, address arbitrumContract) internal {
        console.log("Configuring Ethereum Sepolia -> Arbitrum Sepolia");
        console.log("Ethereum Contract:", ethereumContract);
        console.log("Arbitrum Contract:", arbitrumContract);

        // 使用合约地址直接调用

        // Set peer for Arbitrum Sepolia using V2 interface
        bytes32 arbitrumContractAddress = bytes32(uint256(uint160(arbitrumContract)));

        // Call the setPeer method directly on the adapter
        (bool success,) = ethereumContract.call(
            abi.encodeWithSignature("setPeer(uint32,bytes32)", ARBITRUM_SEPOLIA_CHAIN_ID, arbitrumContractAddress)
        );
        require(success, "Failed to set peer on Ethereum contract");

        console.log("Peer set for Ethereum Sepolia -> Arbitrum Sepolia");
    }

    function configureArbitrumToEthereum(address arbitrumContract, address ethereumContract) internal {
        console.log("Configuring Arbitrum Sepolia -> Ethereum Sepolia");
        console.log("Arbitrum Contract:", arbitrumContract);
        console.log("Ethereum Contract:", ethereumContract);

        // 使用合约地址直接调用

        // Set peer for Ethereum Sepolia using V2 interface
        bytes32 ethereumContractAddress = bytes32(uint256(uint160(ethereumContract)));

        // Call the setPeer method directly on the OFT
        (bool success,) = arbitrumContract.call(
            abi.encodeWithSignature("setPeer(uint32,bytes32)", ETHEREUM_SEPOLIA_CHAIN_ID, ethereumContractAddress)
        );
        require(success, "Failed to set peer on Arbitrum contract");

        console.log("Peer set for Arbitrum Sepolia -> Ethereum Sepolia");
    }
}
