// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../common/ThriftboxStructs.sol";

interface IThriftboxConfiguration {
    function updateConfig(ThriftboxConfig calldata config) external;

    function getConfig() external view returns (ThriftboxConfig memory);
}
