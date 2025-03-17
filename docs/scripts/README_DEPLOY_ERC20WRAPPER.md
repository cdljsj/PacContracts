# ERC20Wrapper Deployment Guide

This document provides detailed instructions on how to use the `DeployERC20Wrapper.s.sol` script to create a wrapper contract for an already deployed ERC20 token.

## Overview

The ERC20Wrapper contract can wrap any existing ERC20 token into a new token with additional functionality, including:
- ERC20Permit support (no separate approval transaction needed)
- Batch operation support
- Token deposit and withdrawal functions

## Prerequisites

1. Address of an already deployed ERC20 token contract
2. Foundry toolchain installed
3. Sufficient ETH to pay for deployment transaction fees

## Environment Variable Setup

Before deployment, set the following environment variables in your `.env` file:

```bash
# Required environment variables
UNDERLYING_TOKEN_ADDRESS=0xYourDeployedERC20TokenAddress  # e.g., MockERC20 address

# Optional environment variables (defaults will be used if not set)
WRAPPER_NAME="Wrapped Token Name"  # Default: "Wrapped " + original token name
WRAPPER_SYMBOL="wTKN"              # Default: "w" + original token symbol
INITIAL_DEPOSIT=0                  # Default: 0 (initial amount of tokens to deposit)

# RPC URL and deployment account configuration (same as before)
ETH_RPC_URL=https://eth-sepolia.public.blastapi.io
ETH_FROM=0xYourDeploymentAccountAddress
```

## Deployment Command

```bash
# Load environment variables
source .env

# Deploy ERC20Wrapper contract
forge script script/DeployERC20Wrapper.s.sol:DeployERC20Wrapper \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv

# For automatic verification during deployment, add these parameters
# --verify \
# --etherscan-api-key $ETHERSCAN_API_KEY
```

## Manual Contract Verification

If you didn't verify the contract during deployment, you can manually verify it using the following command:

```bash
# Verify the ERC20Wrapper contract
forge verify-contract <DEPLOYED_CONTRACT_ADDRESS> src/ERC20Wrapper.sol:ERC20Wrapper \
  --chain-id 11155111 \
  --constructor-args $(cast abi-encode "constructor(address,string,string)" $UNDERLYING_TOKEN_ADDRESS "$WRAPPER_NAME" "$WRAPPER_SYMBOL") \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

Replace `<DEPLOYED_CONTRACT_ADDRESS>` with the address of your deployed wrapper contract. The other parameters will be taken from your environment variables.
```

## Post-Deployment Operations

1. **Record Deployment Address**: The deployment script will output the ERC20Wrapper contract address. Make sure to record this address.

2. **Deposit Tokens**: To use the wrapper functionality, you need to first deposit original tokens into the ERC20Wrapper contract.

   ```bash
   # First approve the ERC20Wrapper contract to use your tokens
   cast send $UNDERLYING_TOKEN_ADDRESS "approve(address,uint256)" $WRAPPER_ADDRESS DEPOSIT_AMOUNT --from YOUR_ADDRESS --private-key YOUR_PRIVATE_KEY
   
   # Then deposit tokens
   cast send $WRAPPER_ADDRESS "deposit(uint256)" DEPOSIT_AMOUNT --from YOUR_ADDRESS --private-key YOUR_PRIVATE_KEY
   ```

3. **Verify Contract**: Verify the contract on Etherscan so users can interact with it.

## Using the Wrapped Token

The wrapped token provides the following main functions:

1. **Deposit Original Tokens**:
   - `deposit(uint256 amount)`: Deposit original tokens and receive an equal amount of wrapped tokens
   - `depositFor(address from, address to, uint256 amount)`: Deposit tokens on behalf of someone else

2. **Withdraw Original Tokens**:
   - `withdraw(uint256 amount)`: Burn wrapped tokens and withdraw original tokens
   - `withdrawTo(address to, uint256 amount)`: Withdraw original tokens to a specified address

3. **ERC20Permit Functionality**:
   - `permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)`: Allow token transfers via signature

## Important Notes

1. Ensure you have enough ETH to pay for deployment and interaction transaction fees.
2. The wrapped token will have the same number of decimals as the original token.
3. Before deploying to mainnet, it's recommended to test on a testnet first.
4. The total supply of wrapped tokens will equal the amount of original tokens deposited into the contract.

## Troubleshooting

1. **Deployment Failure**:
   - Check if your RPC URL is correct
   - Ensure you have enough ETH to pay for transaction fees
   - Verify that environment variables are set correctly

2. **Deposit Failure**:
   - Make sure you have approved the ERC20Wrapper contract to use your tokens
   - Check if your original token balance is sufficient

3. **Withdrawal Failure**:
   - Ensure you have enough wrapped token balance
   - Check if the ERC20Wrapper contract has enough original tokens
