// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "./common/VoucherStorage.sol";
import "./common/VoucherErrors.sol";

contract VoucherModifiers is VoucherStorage {
    modifier isStakingOrOwner() {
        if (msg.sender != _config.stakingAddress && msg.sender != _owner) {
            revert VoucherErrors.NoPermission();
        }
        _;
    }
}
