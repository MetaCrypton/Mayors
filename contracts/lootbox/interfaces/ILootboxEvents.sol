// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

interface ILootboxEvents {
    event ConfigUpdated();
    event SeasonInfoAdded(
        uint256 seasonId,
        uint256 number,
        string uri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox
    );
}
