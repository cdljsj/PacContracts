# UpgradeableOFTAdapter Deployment Guide

This guide provides detailed instructions on how to deploy the UpgradeableOFTAdapter contract to the Ethereum Sepolia testnet using the `DeployUpgradeableOFTAdapter.s.sol` script.

## Overview

The UpgradeableOFTAdapter contract is an upgradeable adapter that wraps existing ERC20 tokens and makes them compatible with LayerZero's OFT protocol, enabling cross-chain functionality. This adapter follows the UUPS upgradeable pattern.

## Prerequisites

1. Address of an already deployed ERC20 token contract
2. LayerZero endpoint contract address
3. Foundry toolchain installed
4. Sufficient ETH to pay for deployment transaction fees
5. Etherscan API key (for contract verification)

## Environment Variables Setup

Before deployment, set the following environment variables in your `.env` file:

```bash
# Required environment variables
TOKEN_ADDRESS=0xYourERC20TokenAddress  # The ERC20 token address you want to adapt
LZ_ENDPOINT=0xLayerZeroEndpointAddress  # LayerZero endpoint address
OWNER_ADDRESS=0xYourOwnerAddress  # Contract owner address (capable of upgrades and configuration)

# RPC URL and deployment account configuration
ETH_RPC_URL=https://eth-sepolia.public.blastapi.io
PRIVATE_KEY=your_private_key_here

# Verification
ETHERSCAN_API_KEY=your_etherscan_api_key  # For contract verification
```

## Deployment Command

```bash
# Load environment variables
source .env

# Deploy UpgradeableOFTAdapter contract
forge script script/DeployUpgradeableOFTAdapter.s.sol:DeployUpgradeableOFTAdapter \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv

# If you need to automatically verify the contract during deployment, add these parameters
# --verify \
# --etherscan-api-key $ETHERSCAN_API_KEY
```

## Manual Contract Verification

If you didn't verify the contract during deployment, you can manually verify it using the following commands:

```bash
# Verify implementation contract
forge verify-contract <IMPLEMENTATION_ADDRESS> src/UpgradeableOFTAdapter.sol:UpgradeableOFTAdapter \
  --chain-id 11155111 \
  --constructor-args $(cast abi-encode "constructor(address,address)" $TOKEN_ADDRESS $LZ_ENDPOINT) \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch

# Verify proxy contract
# Note: The proxy contract typically doesn't need separate verification as it's a standard ERC1967Proxy
```

Replace `<IMPLEMENTATION_ADDRESS>` with the address of your deployed implementation contract. Other parameters will be taken from your environment variables.

## Post-Deployment Operations

1. **Record Contract Addresses**: The deployment script will output the addresses of both the implementation and proxy contracts. Make sure to record these addresses, especially the proxy address, as users will interact with the proxy contract.

2. **Configure Cross-Chain Parameters**: After deployment, you'll need to configure the OFT adapter's cross-chain parameters, such as setting peer contract addresses on remote chains and message passing fees.

3. **Verify Functionality**: Test the contract functionality with simple transactions to ensure it works as expected.

4. **Set Permissions**: Ensure appropriate addresses are granted necessary permissions, such as upgrade permissions and configuration permissions.

## Important Notes

- The proxy contract is the one users will interact with.
- The implementation contract contains the logic but should not be interacted with directly.
- This contract follows the UUPS upgradeable pattern, which means the upgrade logic is in the implementation contract, not in the proxy.
- Ensure the private key of the address with upgrade permissions is stored securely.

