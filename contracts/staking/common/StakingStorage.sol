// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./StakingStructs.sol";
import "../../common/ownership/OwnableStorage.sol";

contract StakingStorage is OwnableStorage {
    StakingConfig internal _config;

    uint256 internal _votesThreshold;

    mapping(address => Stake[]) internal _stakes;
}
