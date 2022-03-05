// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../Lootbox.sol";
import "../../common/test/TestNumber.sol";

contract TestLootbox is Lootbox, TestNumber {}

contract TestLootboxInc is Lootbox, TestNumberInc {}
