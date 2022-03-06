// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./OwnableStorage.sol";

contract Ownable is OwnableStorage {
    error SameOwner();
    error NotOwner();

    event OwnershipTransferred(address to);

    modifier isOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    //solhint-disable-next-line comprehensive-interface
    function transferOwnership(address to) external isOwner {
        if (_owner == to) revert SameOwner();
        _owner = to;
        emit OwnershipTransferred(to);
    }
}
