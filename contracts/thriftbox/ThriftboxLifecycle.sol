// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "../common/erc20/ERC20.sol";
import "./interfaces/IThriftboxEvents.sol";
import "./interfaces/IThriftboxLifecycle.sol";
import "./ThriftboxModifiers.sol";

contract ThriftboxLifecycle is IThirftboxLifecycle, IThriftboxEvents, ThriftboxModifiers {

    function withdrawVotes() external override {
        VotesDeposit storage deposit = _deposits[msg.sender];

        // check balance
        uint256 amount = deposit.amount;
        if (IERC20(_config.votesAddress).balanceOf(address(this)) < amount) revert ThriftboxErrors.NotEnoughVotes();

        // check interval in time between last withdrawal and now
        // solhint-disable not-rely-on-time
        uint256 withdrawalDate = deposit.withdrawalDate;
        if (withdrawalDate != 0) {
            uint256 shiftedDate = withdrawalDate + 7 days;
            if (shiftedDate > block.timestamp) revert ThriftboxErrors.TooFrequentWithdrawals();
        }

        deposit.withdrawalDate = block.timestamp;
        deposit.amount = 0;
        emit VotesWithdrawn(msg.sender, withdrawalDate, amount);
        IERC20(_config.votesAddress).transfer(msg.sender, amount);
        // solhint-enable not-rely-on-time
    }

    function depositVotesList(Earning[] calldata earnings) external override {
        uint256 earningsCount = earnings.length;
        for (uint256 i = 0; i < earningsCount; i++) {
            depositVotes(earnings[i].player, earnings[i].amount);
        }
    }

    function depositVotes(address player, uint256 amount) public override isVotingOrOwner {
        VotesDeposit storage deposit = _deposits[msg.sender];

        // TODO: check overflow
        deposit.amount += amount;

        emit VotesDeposited(player, amount);
        IERC20(_config.votesAddress).transferFrom(msg.sender, address(this), amount);
    }

    function getVotesDeposit(address player) public view override returns (VotesDeposit memory) {
        return _deposits[player];
    }
}
