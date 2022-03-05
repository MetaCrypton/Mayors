// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/interfaces/IERC20.sol";
import "../common/interfaces/IERC20Metadata.sol";
import "../common/interfaces/IERC20Mintable.sol";
import "../common/interfaces/IERC165.sol";

interface IToken is IERC165, IERC20, IERC20Metadata, IERC20Mintable {
    /**
     * @dev Mints tokens to several recipients.
     */
    function batchMint(address[] calldata recipients, uint256 value) external;

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner
    ) external;
}
