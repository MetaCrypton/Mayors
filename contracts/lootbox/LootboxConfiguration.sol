// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/ILootbox.sol";
import "./LootboxErrors.sol";
import "./LootboxStorage.sol";

contract LootboxConfiguration is ILootboxConfiguration, ILootboxEvents, LootboxStorage {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) LootboxStorage(name_, symbol_, owner) {}

    function updateConfig(LootboxConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert LootboxErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (LootboxConfig memory) {
        return _config;
    }
}
