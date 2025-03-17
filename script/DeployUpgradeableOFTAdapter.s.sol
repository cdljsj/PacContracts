// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { console } from "forge-std/src/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/UpgradeableOFTAdapter.sol";
import { BaseScript } from "./Base.s.sol";

/// @dev Script to deploy UpgradeableOFTAdapter to Sepolia testnet
contract DeployUpgradeableOFTAdapter is BaseScript {
    function run() public broadcast returns (address proxyAddress) {
        address owner = vm.envAddress("OWNER_ADDRESS");
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");

        // Deploy implementation contract
        UpgradeableOFTAdapter implementation = new UpgradeableOFTAdapter(tokenAddress, lzEndpoint);

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(UpgradeableOFTAdapter.initialize.selector, owner);

        // Deploy ERC1967Proxy (UUPS pattern)
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // The proxy address is the address users will interact with
        proxyAddress = address(proxy);

        console.log("Implementation deployed at:", address(implementation));
        console.log("Proxy deployed at:", proxyAddress);
        console.log("Token being wrapped:", tokenAddress);
        console.log("LayerZero Endpoint:", lzEndpoint);
        console.log("Owner/Delegate:", owner);
        console.log("To interact with the contract, use the proxy address");
    }
}
