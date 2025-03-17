# Environment Variables Setup for MockERC20 Deployment

To deploy the MockERC20 token to Sepolia, you need to set up your `.env` file correctly. Here's how to modify your current `.env` file:

```bash
# Existing variables (keep these)
export PAC_MMF_WRAPPER="YOUR_PAC_MMF_WRAPPER_ADDRESS"
export SUPRA_PRICE_FEEDS="YOUR_SUPRA_PRICE_FEEDS_ADDRESS"
export SUPRA_PAIR_ID="YOUR_SUPRA_PAIR_ID"
export ADMIN_ADDRESS="YOUR_ADMIN_ADDRESS"

# Sepolia RPC URL (keep this)
ETH_RPC_URL=https://eth-sepolia.public.blastapi.io

# IMPORTANT: Replace PRIVATE_KEY with one of these authentication methods:
# Method 1: Set ETH_FROM (the address that will deploy the contract)
ETH_FROM=0xYourAddressHere

# Method 2: Set MNEMONIC (seed phrase)
# MNEMONIC="your twelve word seed phrase here"

# When running the forge script command, use --private-key flag with your private key
# Example: forge script ... --private-key YOUR_PRIVATE_KEY_HERE

# Token parameters (keep these)
TOKEN_NAME="PacMMF Token"
TOKEN_SYMBOL="PacMMF"
TOKEN_DECIMALS=18
INITIAL_MINT=100000000000000000000000000

# For Etherscan verification (update this)
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Deployment Command

```bash
# Load environment variables
source .env

# Deploy using private key (recommended for testnet)
forge script script/DeployMockERC20.s.sol:DeployMockERC20 \
  --rpc-url $ETH_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv

# If you want to verify the contract on Etherscan, add:
# --verify \
# --etherscan-api-key $ETHERSCAN_API_KEY
```

## Important Notes

1. The `BaseScript` class in your project uses `ETH_FROM` or `MNEMONIC` to determine the broadcaster address, but the actual transaction signing uses the private key provided with the `--private-key` flag.

2. For security, never commit your `.env` file with real private keys or mnemonics to version control.

3. The `PRIVATE_KEY` variable in your current `.env` file is not used by the deployment script directly - you need to provide it with the `--private-key` flag when running the forge script command.
