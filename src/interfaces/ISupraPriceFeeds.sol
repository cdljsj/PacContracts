// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ISupraPriceFeeds {
    function getSvalue(bytes32 _pairId) external view returns (uint256, uint256);
    function checkPrice(bytes32 _pairId) external view returns (uint256);
}
