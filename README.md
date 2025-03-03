# PAC (Protocol Abstraction Contracts) [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

A collection of smart contracts that provide protocol abstraction and standardization for various DeFi protocols.

## Contracts

### ERC20Wrapper

A wrapper contract that allows wrapping of any ERC20 token. Features include:

- 1:1 wrapping and unwrapping of tokens
- Support for deposits on behalf of other addresses
- Permit functionality for gasless approvals
- Maintains same decimals as underlying token
- Full test coverage

## Development

This project uses:

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts): Battle-tested smart contract library
- [Foundry](https://getfoundry.sh/): Ethereum development framework

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- [Node.js](https://nodejs.org/)
- [Bun](https://bun.sh/)

### Setup

```bash
# Install dependencies
bun install

# Build contracts
forge build

# Run tests
forge test

# Run tests with coverage
forge coverage --report lcov && genhtml lcov.info --output-directory coverage
```

### Deployment

```bash
# Deploy to local Anvil chain
forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545

# Deploy to mainnet (requires RPC URL)
forge script script/Deploy.s.sol --broadcast --fork-url $MAINNET_RPC_URL
```

## License

This project is licensed under MIT.
