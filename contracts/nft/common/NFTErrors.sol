// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

library NFTErrors {
    error NoPermission();
    error SameAddress();
    error SameConfig();
    error SameRates();
    error NotEligible();
    error WrongRarity();
    error Overflow();
    error UnexistingToken();
    error EmptyName();
    error SameValue();
    error WrongLevel();
    error MaxLevel();
}
