// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./IMarketplaceEvents.sol";
import "./IMarketplaceConfiguration.sol";
import "./IMarketplacePrimary.sol";
import "./IMarketplaceSecondary.sol";
import "../common/MarketplaceStructs.sol";

interface IMarketplace is IMarketplaceEvents, IMarketplaceConfiguration, IMarketplacePrimary, IMarketplaceSecondary {}
