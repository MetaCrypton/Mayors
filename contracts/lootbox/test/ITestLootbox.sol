// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../interfaces/ILootbox.sol";
import "../../common/test/ITestNumber.sol";

interface ITestLootbox is ILootboxLifecycle, ITestNumber {}

interface ITestLootboxInc is ILootboxLifecycle, ITestNumberInc {}
