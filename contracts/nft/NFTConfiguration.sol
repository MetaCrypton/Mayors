// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./NFTCommons.sol";
import "./interfaces/INFT.sol";
import "./NFTErrors.sol";

contract NFTConfiguration is INFTConfiguration, INFTEvents, NFTCommons {
    function updateConfig(NFTConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert NFTErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (NFTConfig memory) {
        return _config;
    }
}
