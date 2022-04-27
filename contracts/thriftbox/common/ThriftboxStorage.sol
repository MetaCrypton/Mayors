// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./ThriftboxStructs.sol";
import "../../common/ownership/OwnableStorage.sol";

contract ThriftboxStorage is OwnableStorage {
    ThriftboxConfig internal _config;

    mapping(address => VotesDeposit) internal _deposits;
}
