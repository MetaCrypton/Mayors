// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/ownership/Ownable.sol";
import "./common/VoteErrors.sol";
import "./common/VoteStorage.sol";
import "./interfaces/IVoteConfiguration.sol";
import "./interfaces/IVoteEvents.sol";

contract VoteConfiguration is IVoteConfiguration, IVoteEvents, Ownable, VoteStorage {
    function updateConfig(VoteConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert VoteErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (VoteConfig memory) {
        return _config;
    }
}
