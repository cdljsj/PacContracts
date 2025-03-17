# Guide to Deploy MockERC20 to Sepolia Testnet

This guide will help you deploy a MockERC20 token to the Ethereum Sepolia testnet.

## Prerequisites

1. Ensure you have the Foundry toolkit installed
2. Ensure you have an RPC URL for the Sepolia testnet
3. Ensure you have a wallet with testnet ETH (for transaction fees)

## Environment Variable Setup

Before deployment, you can customize token parameters through environment variables. Create or modify the `.env` file in the project root directory:

```bash
# Sepolia RPC URL
ETH_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
# Or use Alchemy
# ETH_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY

# Deployment account configuration (use ONE of the following methods):
# Method 1: Direct address (if you're using --private-key flag with forge script)
ETH_FROM=0xYourAddressHere

# Method 2: Mnemonic (seed phrase)
# MNEMONIC="your twelve word seed phrase here"

# Token parameters (optional, have default values)
TOKEN_NAME="Mock Token"
TOKEN_SYMBOL="MTK"
TOKEN_DECIMALS=18
INITIAL_MINT=1000000000000000000000000  # 1,000,000 tokens with 18 decimals

# For Etherscan verification (optional)
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Deployment Command

Use the following command to deploy the MockERC20 token to the Sepolia testnet:

```bash
# Load environment variables
source .env

# Deploy to Sepolia testnet
# Method 1: Using ETH_FROM with private key
forge script script/DeployMockERC20.s.sol:DeployMockERC20 \
  --rpc-url $ETH_RPC_URL \
  --private-key YOUR_PRIVATE_KEY_HERE \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvv

# OR Method 2: Using MNEMONIC (if set in .env)
forge script script/DeployMockERC20.s.sol:DeployMockERC20 \
  --rpc-url $ETH_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvv
```

If you don't want to verify the contract during deployment, you can omit the `--verify` and `--etherscan-api-key` parameters and verify it manually later.

## Deployment Output

After successful deployment, you will see output similar to the following in the console:

```
MockERC20 token deployed to Sepolia:
Token Address: 0x...
Name: Mock Token
Symbol: MTK
Decimals: 18
Initial supply minted to: 0x...
Initial mint amount: 1000000000000000000000000
```

Record the token address, you will need it to interact with the token.

## Manual Contract Verification

If you didn't verify the contract during deployment, you can manually verify it using the following command:

```bash
# Verify the MockERC20 contract
forge verify-contract <DEPLOYED_CONTRACT_ADDRESS> tests/mocks/MockERC20.sol:MockERC20 \
  --chain-id 11155111 \
  --constructor-args $(cast abi-encode "constructor(string,string,uint8)" "$TOKEN_NAME" "$TOKEN_SYMBOL" $TOKEN_DECIMALS) \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

Replace `<DEPLOYED_CONTRACT_ADDRESS>` with the address of your deployed MockERC20 contract. The other parameters will be taken from your environment variables.

## Verifying the Token

After deployment, you can search for your token address on [Sepolia Etherscan](https://sepolia.etherscan.io/) to verify that the deployment was successful.

## Notes

- Ensure your wallet has sufficient Sepolia ETH to pay for transaction fees
- If you need Sepolia testnet ETH, you can get it from the [Sepolia Faucet](https://sepoliafaucet.com/)
- The deployment script will mint 1,000,000 tokens to the deployer's address by default, you can modify this amount by setting the `INITIAL_MINT` environment variable
