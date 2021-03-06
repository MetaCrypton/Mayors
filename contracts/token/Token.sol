// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./IToken.sol";
import "../common/erc20/ERC20.sol";
import "../common/ownership/Ownable.sol";

contract Token is IToken, ERC20, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) ERC20(name_, symbol_) {
        _owner = owner;
    }

    /**
     * @dev Mints tokens to several recipients.
     */
    function batchMint(address[] calldata recipients, uint256 value) external override isOwner {
        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; i++) {
            _mint(recipients[i], value);
        }
    }

    /**
     * @dev Mints tokens. See {ERC20-_mint}.
     */
    function mint(address recipient, uint256 value) public override isOwner {
        _mint(recipient, value);
    }
}
