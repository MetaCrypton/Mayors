// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/ILootbox.sol";
import "./common/LootboxErrors.sol";
import "./common/LootboxStorage.sol";
import "../common/ownership/Ownable.sol";

contract LootboxConfiguration is ILootboxConfiguration, ILootboxEvents, Ownable, LootboxStorage {
    function updateConfig(LootboxConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert LootboxErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (LootboxConfig memory) {
        return _config;
    }
}
