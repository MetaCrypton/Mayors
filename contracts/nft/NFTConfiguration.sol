// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./common/NFTStorage.sol";
import "./interfaces/INFT.sol";
import "./common/NFTErrors.sol";
import "../common/ownership/Ownable.sol";

contract NFTConfiguration is INFTConfiguration, INFTEvents, Ownable, NFTStorage {
    function updateConfig(NFTConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert NFTErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function updateSeason(string calldata uri) external override isOwner {
        uint length = _seasons.length;
        _seasons.push(Season(uri, 0)); // lastId == 0 -> ongoing season

        uint lastId = _tokenIdCounter - 1;
        if (lastId == 0 || (length > 1 && _seasons[length - 2].lastId == lastId)) revert NFTErrors.NoTokensInSeason();

        _seasons[length - 1].lastId = lastId;

        emit SeasonUpdated(uri);
    }

    function getConfig() external view override returns (NFTConfig memory) {
        return _config;
    }

    function getSeason(uint256 i) external view override returns (Season memory) {
        return _seasons[i];
    }
}
