// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../interfaces/INFT.sol";
import "../../common/test/ITestNumber.sol";

interface ITestNFT is INFTMayor, ITestNumber {}

interface ITestNFTInc is INFTMayor, ITestNumberInc {}
