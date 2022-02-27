// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IMarketplace.sol";
import "./MarketplaceErrors.sol";
import "./MarketplaceStorage.sol";

contract MarketplaceConfiguration is IMarketplaceConfiguration, IMarketplaceEvents, MarketplaceStorage {
    constructor(MarketplaceConfig memory config, address owner) MarketplaceStorage(config, owner) {}

    function updateConfig(MarketplaceConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert MarketplaceErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (MarketplaceConfig memory) {
        return _config;
    }
}
