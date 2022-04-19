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
    function mint(address recipient, uint256 value) public override(ERC20, IERC20Mintable) isOwner {
        super.mint(recipient, value);
    }

    // /**
    //  * @dev Destroys `amount` tokens from the caller.
    //  *
    //  * See {ERC20-_burn}.
    //  */
    // function burn(uint256 amount) public virtual {
    //     _burn(_msgSender(), amount);
    // }

    // /**
    //  * @dev Destroys `amount` tokens from `account`, deducting from the caller's
    //  * allowance.
    //  *
    //  * See {ERC20-_burn} and {ERC20-allowance}.
    //  *
    //  * Requirements:
    //  *
    //  * - the caller must have allowance for ``accounts``'s tokens of at least
    //  * `amount`.
    //  */
    // function burnFrom(address account, uint256 amount) public virtual {
    //     _spendAllowance(account, _msgSender(), amount);
    //     _burn(account, amount);
    // }
}
