// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./IStakingMain.sol";
import "./IStakingConfiguration.sol";
import "./IStakingEvents.sol";
import "../common/StakingStructs.sol";

interface IStaking is IStakingConfiguration, IStakingMain, IStakingEvents {}
