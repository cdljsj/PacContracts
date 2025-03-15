// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/src/Script.sol";
import { console } from "forge-std/src/console.sol";
import "../src/UpgradeableOFT.sol";

contract UpgradeOFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT");
        UpgradeableOFT newImplementation = new UpgradeableOFT(lzEndpoint);

        // Get the proxy contract
        UpgradeableOFT proxy = UpgradeableOFT(proxyAddress);

        // Upgrade the proxy to the new implementation
        // For UUPS, we need to use upgradeToAndCall with empty bytes for no function call
        proxy.upgradeToAndCall(address(newImplementation), "");

        console.log("New implementation deployed at:", address(newImplementation));
        console.log("Proxy upgraded to new implementation");

        vm.stopBroadcast();
    }
}
