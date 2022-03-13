// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./IInventoryAsset.sol";
import "./IInventoryEventsERC20.sol";

interface IInventoryERC20 is IInventoryAsset, IInventoryEventsERC20 {
    function depositERC20(
        address from,
        address token,
        uint256 amount
    ) external;

    function withdrawERC20(
        address recipient,
        address token,
        uint256 amount
    ) external;

    function getERC20s(uint256 startIndex, uint256 number) external view returns (ERC20Struct[] memory);

    function getERC20Balance(address token) external view returns (uint256);
}
