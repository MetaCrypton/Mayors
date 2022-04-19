// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "./common/StakingStorage.sol";
import "./interfaces/IStaking.sol";
import "./StakingConfiguration.sol";
import "./StakingMain.sol";

contract Staking is StakingMain, StakingConfiguration {
    constructor(StakingConfig memory config, address owner) {
        _config = config;
        _owner = owner;
    }
}
