// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./StakingMain.sol";
import "./interfaces/IStakingMain.sol";
import "./interfaces/IStakingEvents.sol";
import "./common/StakingConstants.sol";
import "./common/StakingErrors.sol";
import "./common/StakingStorage.sol";
import "../common/ownership/Ownable.sol";
import "../common/interfaces/IERC20.sol";
import "../voucher/interfaces/IVoucher.sol";

contract StakingMain is IStakingMain, IStakingEvents, Ownable, StakingStorage {
    function stakeVotes(uint256 votesNumber) external override {
        uint256 remainder = votesNumber - (votesNumber / StakingConstants.STAKE_STEP) * StakingConstants.STAKE_STEP;
        if (votesNumber < StakingConstants.STAKE_STEP || remainder != 0) revert StakingErrors.WrongMultiplicity();

        // the first stake must be more then the threshold
        Stake[] storage stakes = _stakes[msg.sender];
        uint256 length = stakes.length;
        if (length == 0 && votesNumber < _votesThreshold) revert StakingErrors.NotEnoughVotesForStake();

        // check delay between stakes
        if (length != 0) {
            Stake memory lastStake = stakes[length - 1];
            if (lastStake.startDate > block.timestamp) revert StakingErrors.StakeDateBeforeNow();

            uint256 timeDelta = block.timestamp - lastStake.startDate;
            if (timeDelta < StakingConstants.STAKE_COOLDOWN) revert StakingErrors.TooOftenStaking();
        }

        // check staker balance
        uint256 votesBalance = IERC20(_config.voteAddress).balanceOf(msg.sender);
        if (votesBalance < votesNumber) revert StakingErrors.NotEnoughVotes();

        // append a new stake
        _addStake(msg.sender, block.timestamp, votesNumber);

        emit VotesStaked(block.timestamp, votesNumber);
        IERC20(_config.voteAddress).transferFrom(msg.sender, address(this), votesNumber);
    }

    function unstakeVotes(uint256 startIndex, uint256 number) external override {
        // remove stakes(and staker if stakes is empty)
        (uint256 vouchersNumber, uint256 votesNumber) = _removeStakes(msg.sender, startIndex, number);

        uint256 votesBalance = IERC20(_config.voteAddress).balanceOf(address(this));
        if (votesBalance < votesNumber) revert StakingErrors.NotEnoughVotes();

        emit VotesUnstaked(msg.sender, votesNumber, vouchersNumber);

        IERC20(_config.voteAddress).transfer(msg.sender, votesNumber);
        if (vouchersNumber == 0) return;
        IVoucher(_config.voucherAddress).mint(msg.sender, vouchersNumber);
    }

    function setThreshold(uint256 threshold) external override isOwner {
        _votesThreshold = threshold;
    }

    function getThreshold() external view override returns (uint256) {
        return _votesThreshold;
    }

    function getStakesNumber(address staker) external view override returns (uint256) {
        Stake[] memory stakes = _stakes[staker];
        return stakes.length;
    }

    function getStakersNumber() external view override returns (uint256) {
        return _stakers.length;
    }

    function getVotesAmount(uint256 startIndex, uint256 number) external view override returns (uint256) {
        Stake[] memory stakes = _stakes[msg.sender];
        uint256 endIndex = startIndex + number;
        if (endIndex > stakes.length) revert StakingErrors.WrongEndIndex();

        uint256 voteNumber;
        for (uint256 i = startIndex; i < endIndex; i++) {
            voteNumber += stakes[i].amount;
        }
        return voteNumber;
    }

    function getVouchersAmount(uint256 startIndex, uint256 number) external view override returns (uint256) {
        Stake[] memory stakes = _stakes[msg.sender];
        uint256 endIndex = startIndex + number;
        if (endIndex > stakes.length) revert StakingErrors.WrongEndIndex();

        uint256 vouchersNumber;
        for (uint256 i = startIndex; i < endIndex; i++) {
            vouchersNumber += _calculateVouchers(stakes[i]);
        }
        return vouchersNumber;
    }

    // TODO: during withdrawal we should merge multiple stakes to the only one. it will free storage
    function withdrawVouchers(
        address staker,
        uint256 startIndex,
        uint256 number
    ) public override isOwner {
        Stake[] storage stakes = _stakes[staker];
        uint256 endIndex = startIndex + number;
        if (endIndex > stakes.length) revert StakingErrors.WrongEndIndex();

        uint256 vouchersNumber;
        for (uint256 i = startIndex; i < endIndex; i++) {
            vouchersNumber += _calculateVouchers(stakes[i]);

            // reset staking time
            stakes[i].startDate = block.timestamp;
        }

        if (vouchersNumber == 0) return;

        emit VouchersMinted(staker, vouchersNumber);
        IVoucher(_config.voucherAddress).mint(staker, vouchersNumber);
    }

    function _addStake(
        address staker,
        uint256 startDate,
        uint256 amount
    ) internal {
        // add staker
        if (_stakes[staker].length == 0) {
            _stakers.push(staker);
            emit StakerAdded(staker);
        }

        // add stake
        Stake memory stake = Stake({ startDate: startDate, amount: amount });
        _stakes[staker].push(stake);
        emit StakeAdded(staker, startDate, amount);
    }

    function _removeStakes(
        address staker,
        uint256 startIndex,
        uint256 number
    ) private returns (uint256 vouchersNumber, uint256 votesNumber) {
        Stake[] storage stakes = _stakes[staker];

        uint256 endIndex = startIndex + number;
        if (endIndex > stakes.length) revert StakingErrors.WrongEndIndex();

        for (uint256 i = endIndex; i > startIndex; i -= 1) {
            Stake memory stake = stakes[i - 1];

            // calc vouchers and votes amounts
            vouchersNumber += _calculateVouchers(stake);
            votesNumber += stake.amount;

            // remove stake
            stakes[i - 1] = stakes[stakes.length - 1];
            stakes.pop();
            emit StakeRemoved(staker, stake.startDate, stake.amount);
        }

        // remove staker
        if (stakes.length == 0) {
            _removeStaker(staker);
        }
    }

    function _removeStaker(address staker) private {
        delete _stakes[staker];

        uint256 length = _stakers.length;
        for (uint256 i = 0; i < length; i++) {
            if (_stakers[i] == msg.sender) {
                _stakers[i] = _stakers[length - 1];
                _stakers.pop();
                emit StakerRemoved(staker);
                break;
            }
        }
    }

    function _calculateVouchers(Stake memory stake) private view returns (uint256) {
        if (stake.startDate > block.timestamp) revert StakingErrors.StakeDateBeforeNow();

        // rounding to whole hours: 10:45 -> 10:00
        uint256 delta = ((block.timestamp - stake.startDate) / 1 hours) * 1 hours;
        uint256 voucherDecimal = 2;
        uint256 precision = 3;

        uint256 votesRatio = (stake.amount * 10**(voucherDecimal + precision)) / StakingConstants.VOTES_PER_VOUCHER;
        uint256 timesRatio = (delta * 10**(voucherDecimal + precision)) / StakingConstants.SECONDS_PER_VOUCHER;
        uint256 result = (votesRatio * timesRatio) / 10**(voucherDecimal + precision * 2);
        return result;
    }
}
