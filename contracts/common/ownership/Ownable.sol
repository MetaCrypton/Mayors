// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

contract Ownable {
    error SameOwner();
    error NotOwner();

    event OwnershipTransferred(address to);

    address internal _owner;

    modifier isOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    constructor(address owner) {
        _owner = owner;
    }

    //solhint-disable-next-line comprehensive-interface
    function transferOwnership(address to) external isOwner {
        if (_owner == to) revert SameOwner();
        _owner = to;
        emit OwnershipTransferred(to);
    }
}
