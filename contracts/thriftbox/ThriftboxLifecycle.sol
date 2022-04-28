// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.

pragma solidity ^0.8.0;

import "../common/erc20/ERC20.sol";
import "../common/ownership/Ownable.sol";
import "./common/ThriftboxErrors.sol";
import "./common/ThriftboxStorage.sol";
import "./interfaces/IThriftboxEvents.sol";
import "./interfaces/IThriftboxLifecycle.sol";

contract ThriftboxLifecycle is IThriftboxLifecycle, IThriftboxEvents, Ownable, ThriftboxStorage {
    function withdrawVotes() external override {
        VotesDeposit storage deposit = _deposits[msg.sender];

        // check balance
        uint256 amount = deposit.amount;
        if (IERC20(_config.votesAddress).balanceOf(address(this)) < amount) revert ThriftboxErrors.NotEnoughVotes();

        // check interval in time between last and current withdrawals
        // solhint-disable not-rely-on-time
        uint256 withdrawalDate = deposit.withdrawalDate;
        if (withdrawalDate != 0) {
            uint256 shiftedDate = withdrawalDate + 7 days;
            if (shiftedDate > block.timestamp) revert ThriftboxErrors.TooFrequentWithdrawals();
        }

        deposit.withdrawalDate = block.timestamp;
        deposit.amount = 0;
        emit VotesWithdrawnByPlayer(msg.sender, withdrawalDate, amount);
        IERC20(_config.votesAddress).transfer(msg.sender, amount);
        // solhint-enable not-rely-on-time
    }

    function depositVotesList(Earning[] calldata earnings) external override isOwner {
        uint256 totalAmount;
        uint256 earningsCount = earnings.length;
        for (uint256 i = 0; i < earningsCount; i++) {
            _depositVotes(earnings[i].player, earnings[i].amount);
            totalAmount += earnings[i].amount;
        }

        emit VotesDepositedTotal(totalAmount);
        IERC20(_config.votesAddress).transferFrom(msg.sender, address(this), totalAmount);
    }

    function getVotesDeposit(address player) external view override returns (VotesDeposit memory) {
        return _deposits[player];
    }

    function _depositVotes(address player, uint256 amount) internal isOwner {
        VotesDeposit storage deposit = _deposits[player];
        deposit.amount += amount;
        emit VotesDepositedByPlayer(player, amount);
    }
}
