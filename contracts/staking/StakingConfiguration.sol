// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/ownership/Ownable.sol";
import "./common/StakingErrors.sol";
import "./common/StakingStorage.sol";
import "./interfaces/IStaking.sol";

contract StakingConfiguration is IStakingConfiguration, IStakingEvents, Ownable, StakingStorage {
    function updateConfig(StakingConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert StakingErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (StakingConfig memory) {
        return _config;
    }
}
