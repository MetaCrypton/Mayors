// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/NFTStructs.sol";

interface INFTEvents {
    event ConfigUpdated();

    event LevelUpdated(uint256 tokenId, Level level);

    event NameSet(uint256 tokenId, string name);

    event SeasonUpdated(string uri);
}
