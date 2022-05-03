// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/LootboxStructs.sol";

interface ILootboxConfiguration {
    function updateConfig(LootboxConfig calldata config, string calldata uri) external;

    function getConfig() external view returns (LootboxConfig memory);
}
