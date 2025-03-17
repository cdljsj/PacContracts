# Guide to Deploy UpgradeableOFT to Base Sepolia Testnet

This guide will help you deploy an UpgradeableOFT token to the Base Sepolia testnet, which is a native OFT token that can be transferred across chains using LayerZero.

## Prerequisites

1. Ensure you have the Foundry toolkit installed
2. Ensure you have an RPC URL for the Base Sepolia testnet
3. Ensure you have a wallet with Base Sepolia testnet ETH (for transaction fees)

## Environment Variable Setup

Before deployment, you need to set up the required environment variables. Create or modify the `.env` file in the project root directory:

```bash
# Base Sepolia RPC URL
BASE_RPC_URL=https://sepolia.base.org

# Deployment account configuration (use ONE of the following methods):
# Method 1: Direct address (if you're using --private-key flag with forge script)
ETH_FROM=0xYourAddressHere

# Method 2: Mnemonic (seed phrase)
# MNEMONIC="your twelve word seed phrase here"

# Required environment variables for UpgradeableOFT deployment
TOKEN_NAME="Your Token Name"
TOKEN_SYMBOL="SYMBOL"
LZ_ENDPOINT=0x6EDCE65403992e310A62460808c4b910D972f10f  # LayerZero Base Sepolia endpoint address
OWNER_ADDRESS=0xYourOwnerAddress  # Contract owner address that can perform upgrades and configurations

# For Etherscan verification (optional)
BASESCAN_API_KEY=your_basescan_api_key
```

> Note: Make sure to use the correct LayerZero endpoint address for Base Sepolia. The address provided above is an example and may need to be updated.

## Deployment Command

Use the following command to deploy the UpgradeableOFT token to the Base Sepolia testnet:

```bash
# Load environment variables
source .env

# Deploy to Base Sepolia testnet
# Method 1: Using private key
forge script script/DeployUpgradeableOFT.s.sol:DeployUpgradeableOFT \
  --rpc-url $BASE_RPC_URL \
  --private-key YOUR_PRIVATE_KEY_HERE \
  --broadcast \
  -vvv

# OR Method 2: Using MNEMONIC (if set in .env)
forge script script/DeployUpgradeableOFT.s.sol:DeployUpgradeableOFT \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  -vvv
```

## Contract Verification

After deployment, you can verify your contract on BaseScan:

```bash
# Verify the implementation contract
forge verify-contract \
  --chain-id 84532 \
  <IMPLEMENTATION_ADDRESS> \
  src/UpgradeableOFT.sol:UpgradeableOFT \
  --constructor-args $(cast abi-encode "constructor(address)" $LZ_ENDPOINT) \
  --etherscan-api-key $BASESCAN_API_KEY \
  --watch

# Verify the proxy contract
forge verify-contract \
  --chain-id 84532 \
  <PROXY_ADDRESS> \
  @openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
  --constructor-args $(cast abi-encode "constructor(address,bytes)" "<IMPLEMENTATION_ADDRESS>" $(cast abi-encode "function initialize(string,string,address)" "$TOKEN_NAME" "$TOKEN_SYMBOL" "$OWNER_ADDRESS")) \
  --etherscan-api-key $BASESCAN_API_KEY \
  --watch
```

Replace `<IMPLEMENTATION_ADDRESS>` and `<PROXY_ADDRESS>` with the addresses from your deployment output.

## Deployment Output

After successful deployment, you will see output similar to the following in the console:

```
Implementation deployed at: 0x...
Proxy deployed at: 0x...
Token Name: Your Token Name
Token Symbol: SYMBOL
LayerZero Endpoint: 0x...
Owner/Delegate: 0x...
To interact with the contract, use the proxy address
```

Record the proxy address, as this is the address you will use to interact with your token.

## Cross-Chain Setup

After deploying the UpgradeableOFT on Base Sepolia, you'll need to:

1. Set up trusted remote addresses for each chain you want to connect with
2. Configure message libraries and fees for cross-chain transactions

These steps will be covered in a separate guide for cross-chain configuration.
