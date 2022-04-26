// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./VoucherModifiers.sol";
import "./interfaces/IVoucherERC20.sol";
import "./common/VoucherStorage.sol";
import "../common/erc20/ERC20.sol";
import "../common/ownership/Ownable.sol";

contract VoucherERC20 is IVoucherERC20, ERC20, Ownable, VoucherStorage, VoucherModifiers {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /**
     * @dev Mints tokens. See {ERC20-_mint}.
     */
    function mint(address recipient, uint256 value) public override isStakingOrOwner {
        _mint(recipient, value);
    }

    function decimals() public pure override(ERC20, IERC20Metadata) returns (uint8) {
        return 2;
    }
}
