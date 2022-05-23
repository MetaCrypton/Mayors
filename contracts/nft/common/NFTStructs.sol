// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

struct NFTConfig {
    address lootboxAddress;
    address rarityCalculator;
}

struct RarityRates {
    uint8 common;
    uint8 rare;
    uint8 epic;
    uint8 legendary;
}

struct HashrateMultipliers {
    uint8[3] common;
    uint8[3] rare;
    uint8[3] epic;
    uint8[3] legendary;
}

struct VoteDiscounts {
    uint8[3] common;
    uint8[3] rare;
    uint8[3] epic;
    uint8[3] legendary;
}

enum Rarity {
    Common,
    Rare,
    Epic,
    Legendary
}

enum Level {
    Gen0,
    Gen1,
    Gen2
}
