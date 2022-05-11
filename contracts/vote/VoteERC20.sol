// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;
import "./VoteModifiers.sol";
import "./common/VoteConstants.sol";
import "./interfaces/IVoteERC20.sol";
import "../common/erc20/ERC20.sol";
import "../common/ownership/Ownable.sol";

contract VoteERC20 is IVoteERC20, ERC20, Ownable, VoteModifiers {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /**
     * @dev Burns tokens. See {ERC20-_burn}.
     */
    function burn(address recipient, uint256 value) public override isVotingOrOwner {
        _burn(recipient, value);
    }

    function decimals() public pure override(ERC20, IERC20Metadata) returns (uint8) {
        return VoteConstants.DECIMAL;
    }
}
