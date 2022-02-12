// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

/**
 * @title ERC20 Mintable Token
 * @dev ERC20 Token that can be irreversibly minted.
 */
interface IERC20Mintable {
    /**
     * @dev Mints tokens. See {ERC20-_mint}.
     */
    function mint(address recipient, uint256 value) external;
}
