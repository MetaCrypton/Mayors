// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "./interfaces/IVoucher.sol";
import "../common/erc20/ERC20.sol";
import "../common/ownership/Ownable.sol";

contract Voucher is IVoucher, ERC20, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) ERC20(name_, symbol_) {
        _owner = owner;
    }

    /**
     * @dev Mints tokens. See {ERC20-_mint}.
     */
    function mint(address recipient, uint256 value) public override isOwner {
        _mint(recipient, value);
    }

    /**
     * @dev Burns tokens. See {ERC20-_mint}.
     */
    function burn(address recipient, uint256 value) public override isOwner {
        _burn(recipient, value);
    }
}
