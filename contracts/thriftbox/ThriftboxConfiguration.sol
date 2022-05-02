// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IThriftboxEvents.sol";
import "./interfaces/IThriftboxConfiguration.sol";
import "./common/ThriftboxErrors.sol";
import "./common/ThriftboxStorage.sol";
import "../common/ownership/Ownable.sol";

contract ThriftboxConfiguration is IThriftboxConfiguration, IThriftboxEvents, Ownable, ThriftboxStorage {
    function updateConfig(ThriftboxConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert ThriftboxErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (ThriftboxConfig memory) {
        return _config;
    }
}
