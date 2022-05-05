// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./VoucherStructs.sol";
import "../../common/ownership/OwnableStorage.sol";

contract VoucherStorage is OwnableStorage {
    VoucherConfig internal _config;
}
