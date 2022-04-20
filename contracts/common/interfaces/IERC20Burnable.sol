// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

/**
 * @title ERC20 Burnable Token
 * @dev ERC20 Token that can be burned.
 */
interface IERC20Burnable {
    /**
     * @dev Burns tokens. See {ERC20-_burn}.
     */
    function burn(address recipient, uint256 value) external;
}
