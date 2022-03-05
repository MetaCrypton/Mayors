// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../Token.sol";
import "../../common/test/TestNumber.sol";

contract TestToken is Token, TestNumber {}

contract TestTokenInc is Token, TestNumberInc {}
