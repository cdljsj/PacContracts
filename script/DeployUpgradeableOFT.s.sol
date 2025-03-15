// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std/src/Script.sol";
import { console } from "forge-std/src/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/UpgradeableOFT.sol";

contract DeployUpgradeableOFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation contract
        UpgradeableOFT implementation = new UpgradeableOFT(lzEndpoint);

        // Prepare initialization data
        bytes memory initData =
            abi.encodeWithSelector(UpgradeableOFT.initialize.selector, "Upgradeable OFT Token", "UOFT", owner);

        // Deploy ERC1967Proxy (UUPS pattern)
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // The proxy address is the address users will interact with
        console.log("Implementation deployed at:", address(implementation));
        console.log("Proxy deployed at:", address(proxy));
        console.log("To interact with the contract, use the proxy address");

        vm.stopBroadcast();
    }
}
