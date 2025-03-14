// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@layerzerolabs/oft-evm-upgradeable/contracts/oft/OFTAdapterUpgradeable.sol";

/**
 * @title UpgradeableOFTAdapter
 * @dev An upgradeable adapter that wraps an existing ERC20 token and makes it cross-chain compatible
 * using LayerZero's OFT protocol. This adapter follows the UUPS upgradeable pattern.
 */
contract UpgradeableOFTAdapter is OFTAdapterUpgradeable, UUPSUpgradeable {
    /**
     * @dev Constructor that initializes the adapter with the token and LayerZero endpoint
     * @param _token The address of the ERC20 token to adapt
     * @param _lzEndpoint The LayerZero endpoint address for cross-chain functionality
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor(address _token, address _lzEndpoint) OFTAdapterUpgradeable(_token, _lzEndpoint) {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with token details and delegate address
     * @param _delegate The delegate address (typically the owner) capable of making OApp configurations
     */
    function initialize(address _delegate) public initializer {
        __OFTAdapter_init(_delegate);
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Authorizes an upgrade to a new implementation
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
