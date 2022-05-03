// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/ILootbox.sol";
import "./common/LootboxErrors.sol";
import "./common/LootboxStorage.sol";
import "../common/ownership/Ownable.sol";

contract LootboxConfiguration is ILootboxConfiguration, ILootboxEvents, Ownable, LootboxStorage {
    function updateConfig(LootboxConfig calldata config, string calldata uri) external override isOwner {
        if (keccak256(abi.encode(_config, _baseURI)) == keccak256(abi.encode(config, uri)))
            revert LootboxErrors.SameConfig();
        _config = config;
        _baseURI = uri;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (LootboxConfig memory) {
        return _config;
    }
}
