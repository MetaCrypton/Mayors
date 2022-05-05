// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/VoucherStructs.sol";

interface IVoucherConfiguration {
    function updateConfig(VoucherConfig calldata config) external;

    function getConfig() external view returns (VoucherConfig memory);
}
