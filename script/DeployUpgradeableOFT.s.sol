// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/src/Script.sol";
import { console } from "forge-std/src/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/UpgradeableOFT.sol";
import { BaseScript } from "./Base.s.sol";

/// @dev Script to deploy UpgradeableOFT to Base Sepolia testnet
contract DeployUpgradeableOFT is BaseScript {
    function run() public broadcast returns (address proxyAddress) {
        address owner = vm.envAddress("OWNER_ADDRESS");
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT");
        string memory tokenName = vm.envString("TOKEN_NAME");
        string memory tokenSymbol = vm.envString("TOKEN_SYMBOL");

        // Deploy implementation contract
        UpgradeableOFT implementation = new UpgradeableOFT(lzEndpoint);

        // Prepare initialization data
        bytes memory initData =
            abi.encodeWithSelector(UpgradeableOFT.initialize.selector, tokenName, tokenSymbol, owner);

        // Deploy ERC1967Proxy (UUPS pattern)
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // The proxy address is the address users will interact with
        proxyAddress = address(proxy);
        
        console.log("Implementation deployed at:", address(implementation));
        console.log("Proxy deployed at:", proxyAddress);
        console.log("Token Name:", tokenName);
        console.log("Token Symbol:", tokenSymbol);
        console.log("LayerZero Endpoint:", lzEndpoint);
        console.log("Owner/Delegate:", owner);
        console.log("To interact with the contract, use the proxy address");
    }
}
