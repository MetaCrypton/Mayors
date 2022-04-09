// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/MarketplaceStructs.sol";

interface IMarketplaceConfiguration {
    function updateConfig(MarketplaceConfig calldata config) external;

    function addNewSeasons(Season[] calldata seasons) external;

    function getConfig() external view returns (MarketplaceConfig memory);

    function getSeasonsTotal() external view returns (uint256);

    function getSeasons(uint256 start, uint256 number) external view returns (Season[] memory);
}
