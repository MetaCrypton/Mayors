// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

library MarketplaceErrors {
    error NotEligible();
    error TooManyLootboxes();
    error SameValue();
    error NullValue();
    error NotTradable();
    error AlreadyOwner();
    error NotOnSale();
    error SameConfig();
    error OutOfStock();
    error NotValidPrice();
    error NotItemOwner();
}
