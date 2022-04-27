// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

enum Building {
    University,
    Hospital,
    Bank,
    Factory,
    Stadium,
    Monument
}

struct Region {
    bool active;
    uint256 endVotingTimestamp;
}

struct City {
    uint256 regionId;
    string name;
    uint256 population;
    uint256 votePrice;
    bool active;
    uint256 bank;
}

struct NewCity {
    uint256 id;
    string name;
    uint256 population;
    uint256 votePrice;
}

struct Mayor {
    bool elected;
    uint256 mayorId;
}

struct Nominee {
    uint256 mayorId;
    uint256 votes;
}

struct Reward {
    uint256 cityId;
    uint256 amount;
    // uint256 burnAmount;
}