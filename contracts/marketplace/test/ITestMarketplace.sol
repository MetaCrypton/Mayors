// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../interfaces/IMarketplace.sol";
import "../../common/test/ITestNumber.sol";

interface ITestMarketplace is IMarketplaceSecondary, ITestNumber {}

interface ITestMarketplaceInc is IMarketplaceSecondary, ITestNumberInc {}
