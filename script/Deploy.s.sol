// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.28;

import { ERC20Wrapper } from "../src/ERC20Wrapper.sol";
import { MockERC20 } from "../tests/mocks/MockERC20.sol";
import { BaseScript } from "./Base.s.sol";

/// @dev Script to deploy ERC20Wrapper contract
contract Deploy is BaseScript {
    function run() public broadcast returns (ERC20Wrapper wrapper) {
        // First deploy a mock token (in production, you would use an existing token)
        MockERC20 underlying = new MockERC20("Mock Token", "MOCK", 18);

        // Then deploy the wrapper
        wrapper = new ERC20Wrapper(underlying, "Wrapped Mock Token", "wMOCK");
    }
}
