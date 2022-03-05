// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../Marketplace.sol";
import "../../common/test/TestNumber.sol";

contract TestMarketplace is Marketplace, TestNumber {}

contract TestMarketplaceInc is Marketplace, TestNumberInc {}
