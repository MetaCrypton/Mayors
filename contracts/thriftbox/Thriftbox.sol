// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "./ThriftboxConfiguration.sol";
import "./ThriftboxLifecycle.sol";

contract Thriftbox is ThriftboxLifecycle, ThriftboxConfiguration {
    constructor(
        ThriftboxConfig memory config,
        address owner
    ) {
        _config = config;
        _owner = owner;
    }
}
