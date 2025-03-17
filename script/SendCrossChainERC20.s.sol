// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/src/Script.sol";
import { console } from "forge-std/src/console.sol";
import { BaseScript } from "./Base.s.sol";
import { UpgradeableOFTAdapter } from "../src/UpgradeableOFTAdapter.sol";
import { UpgradeableOFT } from "../src/UpgradeableOFT.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Define the interface for the OFT core functions we need for LayerZero v2
interface IOFTv2 {
    struct SendParam {
        uint32 dstEid;
        bytes32 to;
        uint256 amountLD;
        uint256 minAmountLD;
        bytes extraOptions;
        bytes composeMsg;
        bytes oftCmd;
    }
    
    struct MessagingFee {
        uint256 nativeFee;
        uint256 lzTokenFee;
    }
    
    struct MessagingReceipt {
        bytes32 guid;
        uint64 nonce;
        MessagingFee fee;
    }
    
    struct OFTReceipt {
        uint256 amountSentLD;
        uint256 amountReceivedLD;
    }
    
    function quoteSend(
        SendParam calldata _sendParam,
        bool _payInLzToken
    ) external view returns (MessagingFee memory msgFee);
    
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt);
}

/// @dev Script to send ERC20 tokens cross-chain from Ethereum Sepolia to Arbitrum Sepolia
contract SendCrossChainERC20 is BaseScript {
    function run() public broadcast {
        // Get configuration from environment variables
        address ethereumContract = vm.envAddress("ETHEREUM_CONTRACT_ADDRESS"); // OFTAdapter address
        address erc20Token = vm.envAddress("ERC20_TOKEN_ADDRESS"); // Original ERC20 token address
        address recipient = vm.envAddress("RECIPIENT_ADDRESS");
        uint256 amount = vm.envUint("AMOUNT");
        
        // Send ERC20 tokens cross-chain
        sendERC20FromEthereumToArbitrum(ethereumContract, erc20Token, recipient, amount);
    }
    
    function sendERC20FromEthereumToArbitrum(
        address oftAdapterAddress, 
        address erc20TokenAddress, 
        address recipient, 
        uint256 amount
    ) internal {
        console.log("Sending ERC20 tokens from Ethereum Sepolia to Arbitrum Sepolia");
        console.log("OFT Adapter Contract:", oftAdapterAddress);
        console.log("ERC20 Token Address:", erc20TokenAddress);
        console.log("Recipient:", recipient);
        console.log("Amount:", amount);
        
        // Get ERC20 token instance
        IERC20 erc20Token = IERC20(erc20TokenAddress);
        
        // Get OFT Adapter instance for reference (not used directly)
        // UpgradeableOFTAdapter adapter = UpgradeableOFTAdapter(oftAdapterAddress);
        
        // Check ERC20 token balance
        uint256 erc20Balance = erc20Token.balanceOf(broadcaster);
        console.log("Current ERC20 balance:", erc20Balance);
        require(erc20Balance >= amount, "Insufficient ERC20 balance");
        
        // Check ERC20 allowance
        uint256 allowance = erc20Token.allowance(broadcaster, oftAdapterAddress);
        console.log("Current allowance to OFT Adapter:", allowance);
        
        // If allowance is insufficient, approve
        if (allowance < amount) {
            console.log("Approving OFT Adapter to spend ERC20 tokens");
            erc20Token.approve(oftAdapterAddress, type(uint256).max);
            console.log("Approval successful");
        }
        
        // Create adapter parameters for gas estimation
        bytes memory adapterParams = abi.encodePacked(uint16(1), uint256(300000)); // Version 1, gas limit 300000
        
        // Create SendParam struct for LZ v2
        IOFTv2.SendParam memory sendParam = IOFTv2.SendParam({
            dstEid: uint32(ARBITRUM_SEPOLIA_CHAIN_ID),
            to: bytes32(uint256(uint160(recipient))),
            amountLD: amount,
            minAmountLD: amount, // No slippage allowed
            extraOptions: adapterParams,
            composeMsg: bytes(""),
            oftCmd: bytes("")
        });
        
        // Estimate cross-chain fee using quoteSend for LZ v2
        IOFTv2.MessagingFee memory fee = IOFTv2(oftAdapterAddress).quoteSend(
            sendParam,
            false // Not paying in LZ token
        );
        
        console.log("Estimated native fee:", fee.nativeFee);
        
        // Send tokens cross-chain using LZ v2 send method
        IOFTv2(oftAdapterAddress).send{value: fee.nativeFee}(
            sendParam,
            fee,
            payable(broadcaster) // refund address
        );
        
        console.log("Cross-chain ERC20 transfer initiated from Ethereum to Arbitrum");
        console.log("Please wait for the transaction to be confirmed on both chains");
    }
}
