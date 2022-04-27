// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

library VotingConstants {
    uint8 internal constant BUILDING_DISCOUNT_UNIVERSITY = 7;
    uint8 internal constant BUILDING_DISCOUNT_HOSPITAL = 5;

    uint8 internal constant GOVERNANCE_RATE_BANK = 7;
    uint8 internal constant GOVERNANCE_RATE_FACTORY = 5;
    uint8 internal constant GOVERNANCE_RATE_STADIUM = 2;
    uint8 internal constant GOVERNANCE_RATE_MONUMENT = 1;

    uint256 internal constant UNIVERSITY_PRICE = 40000;
    uint256 internal constant HOSPITAL_PRICE = 30000;
    uint256 internal constant BANK_PRICE = 30000;
    uint256 internal constant FACTORY_PRICE = 20000;
    uint256 internal constant STADIUM_PRICE = 8000;
    uint256 internal constant MONUMENT_PRICE = 30000;
}
