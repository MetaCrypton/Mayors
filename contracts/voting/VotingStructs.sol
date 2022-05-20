// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

enum Building {
    Empty,
    University,
    Hospital,
    Bank,
    Factory,
    Stadium,
    Monument
}

struct Region {
    bool active;
    uint256 startVotingTimestamp;
}

struct City {
    uint256 regionId;
    string name;
    uint256 population;
    uint256 votePrice;
    bool active;
}

struct NewCity {
    string name;
    uint256 population;
    uint256 votePrice;
}

struct Nominee {
    uint256 mayorId;
    uint256 votes;
}

// season number starts from 1
struct BuildingInfo {
    Building building;
    uint256 season;
}

struct ClaimInfo {
    uint256 cityId;
    uint256[] seasonIds;
}
