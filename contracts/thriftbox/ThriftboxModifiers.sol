// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "./common/ThriftboxStorage.sol";
import "./common/ThriftboxErrors.sol";

contract ThriftboxModifiers is ThriftboxStorage {
    // TODO: change name of contract
    modifier isVotingOrOwner() {
        if (msg.sender != _config.votingAddress && msg.sender != _owner) {
            revert ThriftboxErrors.NoPermission();
        }
        _;
    }
}
