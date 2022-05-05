// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "./VoucherConfiguration.sol";
import "./VoucherERC20.sol";
import "./interfaces/IVoucher.sol";
import "../common/erc20/ERC20.sol";
import "../common/ownership/Ownable.sol";

contract Voucher is VoucherERC20, VoucherConfiguration {
    constructor(
        string memory name_,
        string memory symbol_,
        VoucherConfig memory config,
        address owner
    ) VoucherERC20(name_, symbol_) {
        _config = config;
        _owner = owner;
    }
}
