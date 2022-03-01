// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IInventory.sol";
import "./InventoryErrors.sol";
import "./InventoryStorage.sol";

contract InventoryConfiguration is IInventoryConfiguration, IInventoryEvents, InventoryStorage {
    constructor(InventoryConfig memory config, address owner) InventoryStorage(config, owner) {}

    function updateConfig(InventoryConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert InventoryErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (InventoryConfig memory) {
        return _config;
    }
}
