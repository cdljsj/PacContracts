// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import { console } from "forge-std/src/console.sol";
import { PacUSD } from "../src/PacUSD.sol";
import { BaseScript } from "./Base.s.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @dev Script to deploy PacUSD contract with UUPS proxy
contract DeployPacUSD is BaseScript {
    function run() public broadcast returns (address proxy, address implementation) {
        // Deploy implementation contract
        PacUSD impl = new PacUSD();
        implementation = address(impl);

        // Encode initialization data
        bytes memory initData = abi.encodeWithSelector(
            PacUSD.initialize.selector,
            vm.envAddress("PAC_MMF_WRAPPER"), // _pacMMF
            vm.envAddress("SUPRA_PRICE_FEEDS"), // _priceFeeds
            vm.envBytes32("SUPRA_PAIR_ID"), // _pairId
            vm.envAddress("ADMIN_ADDRESS") // admin
        );

        // Deploy proxy
        proxy = address(new ERC1967Proxy(implementation, initData));

        console.log("PacUSD Implementation deployed at:", implementation);
        console.log("PacUSD Proxy deployed at:", proxy);
    }
}
