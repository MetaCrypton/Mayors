// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./StakingMain.sol";
import "./interfaces/IStakingMain.sol";
import "./interfaces/IStakingEvents.sol";
import "./common/StakingErrors.sol";
import "./common/StakingStorage.sol";
import "../common/ownership/Ownable.sol";
import "../common/interfaces/IERC20.sol";
import "../voucher/interfaces/IVoucher.sol";

contract StakingMain is IStakingMain, IStakingEvents, Ownable, StakingStorage {
    function changeThreshold(uint256 threshold) external override isOwner {
        _votesThreshold = threshold;
    }

    function stakeVotes(uint256 votesNumber) external override {
        // TODO: check remainder
        if (votesNumber / 100 != 0) revert StakingErrors.WrongMultiplicity();

        // TODO: check threshold

        // TODO: check votes number on the user's wallet

        Stake memory stake = Stake({ startDate: block.timestamp, amount: votesNumber });
        _stakes[msg.sender].push(stake);

        // TODO: (?)change IERC20 to IVote
        IERC20(_config.voteAddress).transferFrom(msg.sender, address(this), votesNumber);
    }

    function unstakeVotes() external override {
        uint256 length = _stakes[msg.sender].length;
        uint256 totalAmount = 0;
        uint256 votesNumber = 0;
        for (uint256 i = 0; i < length; i++) {
            Stake storage stake = _stakes[msg.sender][i];
            totalAmount += _calculateVouchers(stake);
            votesNumber += stake.amount;

            // TODO: free storage
            // delete stake;
        }

        delete _stakes[msg.sender];

        IERC20(_config.voteAddress).transferFrom(address(this), msg.sender, votesNumber);
        IVoucher(_config.voucherAddress).mint(msg.sender, totalAmount);
    }

    function withdrawVouchers(address recipient) external override {
        uint256 length = _stakes[recipient].length;
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < length; i++) {
            Stake storage stake = _stakes[recipient][i];
            totalAmount += _calculateVouchers(stake);

            // reset staking time
            stake.startDate = block.timestamp;
        }

        IVoucher(_config.voucherAddress).mint(recipient, totalAmount);
    }

    function getVouchersAmount() external view override returns (uint256) {
        uint256 length = _stakes[msg.sender].length;
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < length; i++) {
            Stake memory stake = _stakes[msg.sender][i];
            totalAmount += _calculateVouchers(stake);
        }
        return totalAmount;
    }

    function getVotesAmount() external view override returns (uint256) {
        uint256 length = _stakes[msg.sender].length;
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < length; i++) {
            Stake memory stake = _stakes[msg.sender][i];
            totalAmount += stake.amount;
        }
        return totalAmount;
    }

    function _calculateVouchers(Stake memory stake) private view returns (uint256) {
        uint256 delta = block.timestamp - stake.startDate;
        return ((stake.amount / 500) * delta) % (1 days);
    }
}
