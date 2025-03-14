// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@layerzerolabs/oft-evm-upgradeable/contracts/oft/OFTUpgradeable.sol";

/**
 * @title UpgradeableOFT
 * @dev An upgradeable Omnichain Fungible Token (OFT) implementation using LayerZero protocol
 * This contract allows for cross-chain token transfers while maintaining upgradeability
 */
contract UpgradeableOFT is OFTUpgradeable, UUPSUpgradeable {
    /**
     * @dev Constructor that initializes the OFT with the LayerZero endpoint
     * @param _lzEndpoint The LayerZero endpoint address for cross-chain functionality
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor(address _lzEndpoint) OFTUpgradeable(_lzEndpoint) {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with token details and delegate address
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _delegate The delegate address (typically the owner) capable of making OApp configurations
     */
    function initialize(string memory _name, string memory _symbol, address _delegate) public initializer {
        __OFT_init(_name, _symbol, _delegate);
        __Ownable_init(_delegate);
    }

    /**
     * @dev Authorizes an upgrade to a new implementation
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
