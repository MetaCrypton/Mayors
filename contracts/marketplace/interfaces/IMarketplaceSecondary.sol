// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/MarketplaceStructs.sol";

interface IMarketplaceSecondary {
    function setItemForSale(Item calldata item, uint256 price) external;

    function removeItemFromSale(Item calldata item) external;

    function buyItem(Item calldata item) external;

    function getItemPrice(Item calldata item) external view returns (uint256);
}
