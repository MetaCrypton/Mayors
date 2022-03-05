// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../IToken.sol";
import "../../common/test/ITestNumber.sol";

interface ITestToken is IToken, ITestNumber {}

interface ITestTokenInc is IToken, ITestNumberInc {}
