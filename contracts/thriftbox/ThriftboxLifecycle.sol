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
    function withdraw() external override {
        // check balance
        uint256 balance = _balances[msg.sender];
        if (IERC20(_config.votesAddress).balanceOf(address(this)) < balance) revert ThriftboxErrors.NotEnoughVotes();

        // check interval in time between last and current withdrawals
        // solhint-disable not-rely-on-time
        uint256 withdrawalDate = _withrawalDates[msg.sender];
        if (withdrawalDate != 0) {
            uint256 shiftedDate = withdrawalDate + 7 days;
            if (shiftedDate > block.timestamp) revert ThriftboxErrors.TooFrequentWithdrawals();
        }

        _withrawalDates[msg.sender] = block.timestamp;
        delete _balances[msg.sender];
        emit VotesWithdrawnByPlayer(msg.sender, withdrawalDate, balance);
        IERC20(_config.votesAddress).transfer(msg.sender, balance);
        // solhint-enable not-rely-on-time
    }

    function depositList(Earning[] calldata earnings) external override isOwner {
        uint256 totalBalance;
        uint256 earningsCount = earnings.length;
        for (uint256 i = 0; i < earningsCount; i++) {
            _deposit(earnings[i].player, earnings[i].amount);
            totalBalance += earnings[i].amount;
        }

        emit VotesDepositedTotal(totalBalance);
        IERC20(_config.votesAddress).transferFrom(msg.sender, address(this), totalBalance);
    }

    function balanceOf(address player) external view override returns (uint256) {
        return _balances[player];
    }

    function getWithdrawalDate(address player) external view override returns (uint256) {
        return _withrawalDates[player];
    }

    function _deposit(address player, uint256 amount) internal isOwner {
        _balances[player] += amount;
        emit VotesDepositedByPlayer(player, amount);
    }
}
