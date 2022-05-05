// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/ownership/Ownable.sol";
import "./common/VoucherErrors.sol";
import "./common/VoucherStorage.sol";
import "./interfaces/IVoucherConfiguration.sol";
import "./interfaces/IVoucherEvents.sol";

contract VoucherConfiguration is IVoucherConfiguration, IVoucherEvents, Ownable, VoucherStorage {
    function updateConfig(VoucherConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert VoucherErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (VoucherConfig memory) {
        return _config;
    }
}
