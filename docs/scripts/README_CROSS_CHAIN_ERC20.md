# ERC20 Cross-Chain Transfer Guide

This document provides detailed instructions on how to use the `SendCrossChainERC20.s.sol` script to transfer ERC20 tokens from Ethereum Sepolia testnet to Arbitrum Sepolia testnet.

## Prerequisites

Before executing an ERC20 token cross-chain transfer, ensure that:

1. The UpgradeableOFTAdapter contract has been deployed to Ethereum Sepolia testnet
2. The UpgradeableOFT contract has been deployed to Arbitrum Sepolia testnet
3. Cross-chain peer relationships have been configured using the ConfigureCrossChainArbitrum.s.sol script
4. The sending account has sufficient ERC20 token balance on Ethereum Sepolia
5. The sending account has sufficient ETH on Ethereum Sepolia to pay for gas fees and cross-chain fees

## Environment Variable Configuration

Before executing the cross-chain transfer, you need to set the following environment variables:

```bash
# Contract addresses
export ETHEREUM_CONTRACT_ADDRESS=0xC540323158f765b8af3e0b9ed88Ba3bE1a8Eb0a4  # UpgradeableOFTAdapter address on Ethereum Sepolia
export ERC20_TOKEN_ADDRESS=0x...  # Address of the ERC20 token you want to transfer cross-chain

# RPC URL
export ETH_RPC_URL=https://eth-sepolia.public.blastapi.io

# Private key (for signing transactions)
export PRIVATE_KEY=YOUR_PRIVATE_KEY_HERE

# Cross-chain transfer parameters
export RECIPIENT_ADDRESS=0x1D35B2Ed44A8380Fdaa9dc9AbB1926cD998079a8  # Recipient address
export AMOUNT=1000000000000000000  # Amount to send (in wei, this is 1 token assuming 18 decimals)
```

## Executing ERC20 Cross-Chain Transfer

```bash
# Set environment variables (as shown above)

# Execute cross-chain transfer
forge script script/SendCrossChainERC20.s.sol:SendCrossChainERC20 \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
```

## Script Execution Flow

1. **Check ERC20 Balance**: The script first checks if the sending account has sufficient ERC20 token balance.

2. **Check and Approve OFT Adapter**: The script checks if the OFT Adapter has sufficient allowance to transfer ERC20 tokens from the sending account. If the allowance is insufficient, the script automatically approves the required amount.

3. **Estimate Cross-Chain Fee**: The script estimates the native token (ETH) fee required to complete the cross-chain operation.

4. **Execute Cross-Chain Transfer**: The script calls the OFT Adapter's `sendFrom` method to initiate the cross-chain transfer process.

5. **Wait for Confirmation**: Cross-chain transactions need to be confirmed on both networks, which may take some time.

## Important Notes

1. **Ensure Sufficient ETH**: Cross-chain transfers require payment of LayerZero message passing fees, which are paid in ETH.

2. **Confirm Cross-Chain Configuration**: Before executing a cross-chain transfer, ensure that the peer relationship between the two networks has been correctly configured.

3. **Transaction Confirmation Time**: Cross-chain transactions from Ethereum to Arbitrum may take a significant amount of time to complete. Please be patient.

4. **Test with Small Amounts**: When using for the first time, it's recommended to test with a small amount to confirm everything works correctly before making larger transfers.

5. **Check Balances**: Before and after the transfer, use blockchain explorers to check the token balances at the respective addresses to confirm the transfer was successful.

## Troubleshooting

If you encounter issues when executing cross-chain transfers, check the following:

1. Contract addresses are correct
2. You have sufficient ERC20 token balance
3. You have sufficient ETH to pay for gas fees and cross-chain fees
4. Cross-chain peer relationships are correctly configured
5. LayerZero network is operating normally

For more assistance, refer to the LayerZero documentation or contact technical support.
