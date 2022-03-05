// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../NFT.sol";
import "../../common/test/TestNumber.sol";

contract TestNFT is NFT, TestNumber {}

contract TestNFTInc is NFT, TestNumberInc {}
