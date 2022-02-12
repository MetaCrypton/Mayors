// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

struct RarityRates {
    uint256 common;
    uint256 rare;
    uint256 epic;
    uint256 legendary;
}

enum Rarity {
    Common,
    Rare,
    Epic,
    Legendary
}
