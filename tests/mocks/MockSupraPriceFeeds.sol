// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {ISupraPriceFeeds} from "../../src/interfaces/ISupraPriceFeeds.sol";

contract MockSupraPriceFeeds is ISupraPriceFeeds {
    uint256 private _price;

    function setPrice(uint256 price) external {
        _price = price;
    }

    function getPriceData(bytes32) external view returns (uint256, uint256) {
        return (_price, block.timestamp);
    }

    function getSvalue(bytes32) external view returns (uint256, uint256) {
        return (_price, block.timestamp);
    }

    function checkPrice(bytes32) external view returns (uint256) {
        return _price;
    }
}
