// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/MarketplaceStructs.sol";

interface IMarketplaceConfiguration {
    function updateConfig(MarketplaceConfig calldata config) external;

    function setLootboxesForSale(uint256 number) external;

    function addLootboxesForSale(uint256 number) external;

    function burnLootboxesForSale(uint256 number) external;

    function getConfig() external view returns (MarketplaceConfig memory);
}
