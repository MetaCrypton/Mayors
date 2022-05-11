// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "./VoteERC20.sol";
import "./VoteConfiguration.sol";
import "./common/VoteConstants.sol";
import "../common/erc20/ERC20.sol";
import "../common/ownership/Ownable.sol";

contract Vote is VoteERC20, VoteConfiguration {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) VoteERC20(name_, symbol_) {
        _owner = owner;
        _mint(owner, VoteConstants.TOTAL_SUPPLY);
    }
}
