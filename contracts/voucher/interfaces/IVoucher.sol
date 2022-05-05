// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../interfaces/IVoucherConfiguration.sol";
import "../interfaces/IVoucherERC20.sol";
import "../interfaces/IVoucherEvents.sol";

interface IVoucher is IVoucherConfiguration, IVoucherERC20, IVoucherEvents {}
