// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../common/ownership/Ownable.sol";
import "../nft/NFT.sol";
import "../vote/Vote.sol";
import "../voucher/Voucher.sol";
import "./IVoting.sol";
import "./VotingConstants.sol";
import "./VotingStructs.sol";
import "./VotingErrors.sol";

contract Voting is IVoting, Ownable {
    uint256 internal constant VOTING_DURATION = 86400; //24 hours in seconds
    uint256 internal constant GOVERNANCE_DURATION = 86400 * 5; //5 days in seconds
    uint256 internal constant CLAIMING_DURATION = 86400; //24 hours in seconds

    uint256 internal constant PRIZE_RATE = 87;
    uint256 internal constant REWARD_BURN_RATE = 3;

    NFT internal _mayor;
    Vote internal _voteToken;
    Voucher internal _voucherToken;

    // amount of votes for 1 citizen, 4 digits
    uint256 internal _votesPerCitizen;
    uint256 internal _voteDigits;

    // city id => City
    mapping(uint256 => City) internal _cities;
    // region id => Region
    mapping(uint256 => Region) internal _regions;
    // regionId => [city id]
    mapping(uint256 => uint256[]) internal _regionToCities;


    // TODO: change bool to the timestamp for calculating Monument reward? 
    // owner address => city id => Building => 0: not exists, >0: season number +1
    mapping(address => mapping(uint256 => mapping(Building => uint256))) internal _ownerToBuildings;

    // owner address => city id => season => claimed
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) internal _ownerClaims;

    // city id => season id => Nominee
    mapping(uint256 => mapping(uint256 => Nominee[])) internal _cityToNominees;

    uint256 internal _cityIdCounter = 0;

    constructor(
        NFT mayorNFT,
        Vote voteToken_,
        Voucher voucherToken_,
        uint256 votesPerCitizen_,
        address owner
    ) {
        _mayor = mayorNFT;
        _voteToken = voteToken_;
        _voucherToken = voucherToken_;
        _votesPerCitizen = votesPerCitizen_;
        _owner = owner;
        _voteDigits = _voteToken.decimals();
    }

    function transferTokens(address recipient) external override isOwner {
        uint256 voteBalance = _voteToken.balanceOf(address(this));
        uint256 voucherBalance = _voucherToken.balanceOf(address(this));
        _voteToken.transfer(recipient, voteBalance);
        _voucherToken.transfer(recipient, voucherBalance);
    }

    function changeVotesPerCitizen(uint256 amount) external override isOwner {
        if (amount == 0) revert VotingErrors.IncorrectValue();
        uint256 oldAmount = _votesPerCitizen;
        _votesPerCitizen = amount;

        emit VotesPerCitizenUpdated(oldAmount, amount);
    }

    function addCities(uint256 regionId, NewCity[] calldata newCities) external override isOwner {
        if(newCities.length <= 0) revert VotingErrors.EmptyArray();
        uint256[] memory cityIds = new uint256[](newCities.length);

        for (uint256 i = 0; i < newCities.length; i++) {
            NewCity memory newCity = newCities[i];
            City memory city = City({
                regionId: regionId,
                name: newCity.name,
                population: newCity.population,
                votePrice: newCity.votePrice,
                active: true
            });
            _cities[_cityIdCounter] = city;
            _regionToCities[regionId].push(_cityIdCounter);
            cityIds[i] = _cityIdCounter;
            _cityIdCounter++;
        }
        emit CitiesAdded(regionId, cityIds);
        _startVoting(regionId);
    }

    function changeCityVotePrice(uint256 cityId, uint256 newPrice) external override isOwner {
        if (_isVotingPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        if (newPrice == 0) revert VotingErrors.IncorrectValue();
        City storage city = _cities[cityId];
        uint256 oldPrice = city.votePrice;
        if (_cities[cityId].population == 0) revert VotingErrors.IncorrectValue();
        city.votePrice = newPrice;

        emit VotePriceUpdated(cityId, oldPrice, newPrice);
    }

    function addBuilding(
        uint256 cityId,
        uint256 mayorId,
        Building newBuilding
    ) external override {
        if(!_isGoverningPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        if(
            _mayor.ownerOf(mayorId) != msg.sender ||
            _calculateWinner(_seasonNumber(_cities[cityId].regionId) + 1, cityId) != mayorId
        ) revert VotingErrors.WrongMayor();
        uint256 buildingPrice = _getBuildingPrice(newBuilding);
        if(_voucherToken.balanceOf(msg.sender) < buildingPrice) revert VotingErrors.InsufficientBalance();
        if(_ownerToBuildings[msg.sender][cityId][newBuilding] > 0) revert VotingErrors.BuildingDuplicate();
        _ownerToBuildings[msg.sender][cityId][newBuilding] = _seasonNumber(_cities[cityId].regionId) + 1;
        emit BuildingAdded(newBuilding, cityId, msg.sender);
        _voucherToken.transferFrom(msg.sender, address(this), buildingPrice);
    }

    function nominate(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external override {
        if (!_cities[cityId].active) revert VotingErrors.InactiveObject();
        if (!_isVotingPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        if(_mayor.ownerOf(mayorId) != msg.sender) revert VotingErrors.WrongMayor();
        // get the price of those votes
        uint256 priceInVotes = _calculateVotesPrice(mayorId, cityId, votes);
        // check if msg.sender has enough Token balance: balanceOf(msg.sender) >= votes
        if (_voteToken.balanceOf(msg.sender) < priceInVotes) revert VotingErrors.InsufficientBalance();
        // save user vote info
        _cityToNominees[cityId][_seasonNumber(_cities[cityId].regionId) + 1].push(
            Nominee({ mayorId: mayorId, votes: votes })
        );
        emit CandidateAdded(mayorId, cityId, votes);
        // transfer the "votes" amount from user to reward pool
        _voteToken.transferFrom(msg.sender, address(this), priceInVotes);
    }

    function updateCities(uint256[] calldata citiesIds, bool isOpen) external override isOwner {
        for(uint256 i = 0; i < citiesIds.length; i++) {
            if (_isVotingPeriod(_cities[citiesIds[i]].regionId)) revert VotingErrors.IncorrectPeriod();
            _cities[citiesIds[i]].active = isOpen;
            emit CityUpdated(citiesIds[i], isOpen);
        }
    }

    function claimPrize(uint256 cityId, uint256 season) external override {
        if (!_isRewardPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        if (_mayor.ownerOf(_calculateWinner(season, cityId)) == msg.sender) {
            uint256 prize = _calculatePrizeToUser(
                cityId, msg.sender, season, _getBank(_cityToNominees[cityId][season])
            );
            // send tokens to the winner
            if (prize > 0 && !_ownerClaims[msg.sender][cityId][season]) {
                _ownerClaims[msg.sender][cityId][season] = true;
                _voteToken.transfer(msg.sender, prize);
                emit PrizeClaimed(msg.sender, prize);

                // 3% needs to be burned
                _voteToken.burn(address(this), _calculatePrizeToBurn(cityId, season));
            }
        }
    }

    function getWinner(uint256 cityId, uint256 season) external view override returns(uint256) {
        return _calculateWinner(season, cityId);
    }

    function calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external view override returns(uint256) {
        return _calculateVotesPrice(mayorId, cityId, votes);
    }

    function calculatePrize(uint256 cityId, uint256 season) external view override returns(uint256) {
        if (!_isRewardPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        if (_mayor.ownerOf(_calculateWinner(season, cityId)) == msg.sender) {
            uint256 prize = _calculatePrizeToUser(
                cityId, msg.sender, season, _getBank(_cityToNominees[cityId][season])
            );
            return !_ownerClaims[msg.sender][cityId][season] ? prize : 0;
        }
        return 0;
    }

    function _startVoting(uint256 regionId) internal {
        // solhint-disable-next-line not-rely-on-time
        uint256 currentTimestamp = block.timestamp;
        if (_regions[regionId].startVotingTimestamp == 0) {
            _regions[regionId] = Region({active: true, startVotingTimestamp: currentTimestamp});
            emit VotingStarted(regionId, currentTimestamp);
        }
    }

    function _seasonNumber(uint256 regionId) internal view returns(uint256) {
        // solhint-disable-next-line not-rely-on-time
        return (block.timestamp - _regions[regionId].startVotingTimestamp) /
            (VOTING_DURATION + GOVERNANCE_DURATION + CLAIMING_DURATION);
    }

    function _isVotingPeriod(uint256 regionId) internal view returns(bool) {
        // solhint-disable-next-line not-rely-on-time
        return ((block.timestamp - _regions[regionId].startVotingTimestamp) %
            (VOTING_DURATION + GOVERNANCE_DURATION + CLAIMING_DURATION)) < VOTING_DURATION;
    }

    function _isGoverningPeriod(uint256 regionId) internal view returns(bool) {
        /* solhint-disable not-rely-on-time */
        return 
            ((block.timestamp - _regions[regionId].startVotingTimestamp) %
                (VOTING_DURATION + GOVERNANCE_DURATION + CLAIMING_DURATION)) > VOTING_DURATION &&
            ((block.timestamp - _regions[regionId].startVotingTimestamp) %
                (VOTING_DURATION + GOVERNANCE_DURATION + CLAIMING_DURATION)) < (VOTING_DURATION + GOVERNANCE_DURATION);
        /* solhint-enable not-rely-on-time */
    }

    function _isRewardPeriod(uint256 regionId) internal view returns(bool) {
        // solhint-disable-next-line not-rely-on-time
        return ((block.timestamp - _regions[regionId].startVotingTimestamp) %
            (VOTING_DURATION + GOVERNANCE_DURATION + CLAIMING_DURATION)) > (VOTING_DURATION + GOVERNANCE_DURATION);
    }

    function _calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) internal view returns(uint256) {
        if (!_isVotingPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        Nominee[] memory nominees = _cityToNominees[cityId][_seasonNumber(_cities[cityId].regionId) + 1];
        if(
            votes > ((_cities[cityId].population * _votesPerCitizen / 10 ** _voteDigits) - _getBank(nominees))
        ) revert VotingErrors.VotesBankExceeded();
        return (votes * _cities[cityId].votePrice * _getVoteMultiplier(mayorId, cityId, msg.sender)) / 100;
    }

    function _getBuildingsDiscount(uint256 cityId, address account) internal view returns(uint256) {
        if (_ownerToBuildings[account][cityId][Building.University] > 0) {
            return VotingConstants.BUILDING_DISCOUNT_UNIVERSITY;
        } else if (_ownerToBuildings[account][cityId][Building.Hospital] > 0) {
            return VotingConstants.BUILDING_DISCOUNT_HOSPITAL;
        } else {
            return 0;
        }
    }

    function _getVoteMultiplier(
        uint256 nftId,
        uint256 cityId,
        address account
    ) internal view returns(uint256) {
        return 100 - _mayor.getVoteDiscount(nftId) - _getBuildingsDiscount(cityId, account);
    }

    function _calculateWinner(
        uint256 season, 
        uint256 cityId
    ) internal view returns(uint256) {
        Nominee[] memory nominees = _cityToNominees[cityId][season];
        if (nominees.length == 0) revert VotingErrors.IncorrectValue();
        uint256 random = uint256(keccak256(abi.encodePacked(season, cityId)));
        uint256 bank = _getBank(nominees);

        uint256 winnerRate = random % bank;
        uint256 votesCounter = 0;

        for (uint256 i = 0; i < nominees.length; i++) {
            votesCounter += nominees[i].votes;
            if (winnerRate < votesCounter) {
                return nominees[i].mayorId;
            }
        }
    }

    // TODO: calculate Monument rate
    function _calculateGovernanceRate(uint256 cityId, address account, uint256 season) internal view returns(uint256) {
        if (
            _ownerToBuildings[account][cityId][Building.Bank] > 0 &&
            _ownerToBuildings[account][cityId][Building.Bank] <= season
        ) {
            return VotingConstants.GOVERNANCE_RATE_BANK;
        } else if (
            _ownerToBuildings[account][cityId][Building.Factory] > 0 &&
            _ownerToBuildings[account][cityId][Building.Factory] <= season
        ) {
            return VotingConstants.GOVERNANCE_RATE_FACTORY;
        } else if (
            _ownerToBuildings[account][cityId][Building.Stadium] > 0 &&
            _ownerToBuildings[account][cityId][Building.Stadium] <= season
        ) {
            return VotingConstants.GOVERNANCE_RATE_STADIUM;
        } else {
            return 0;
        }
    }

    function _calculatePrizeToUser(
        uint256 cityId,
        address account,
        uint256 season,
        uint256 bank
    ) internal view returns(uint256) {
        return bank * (PRIZE_RATE + _calculateGovernanceRate(cityId, account, season)) / 100;
    }

    function _calculatePrizeToBurn(uint256 cityId, uint256 season) internal view returns(uint256) {
        return _getBank(_cityToNominees[cityId][season]) * REWARD_BURN_RATE / 100;
    }

    function _getBank (Nominee[] memory nominees) internal pure returns (uint256) {
        uint256 bank = 0;
        for (uint256 i = 0; i < nominees.length; i++) {
            bank += nominees[i].votes;
        }
        return bank;
    }

    function _getBuildingPrice(Building building) internal pure returns(uint256) {
        if (building == Building.University) {
            return VotingConstants.UNIVERSITY_PRICE;
        } else if (building == Building.Hospital) {
            return VotingConstants.HOSPITAL_PRICE;
        } else if (building == Building.Bank) {
            return VotingConstants.BANK_PRICE;
        } else if (building == Building.Factory) {
            return VotingConstants.FACTORY_PRICE;
        } else if (building == Building.Stadium) {
            return VotingConstants.STADIUM_PRICE;
        } else {
            return VotingConstants.MONUMENT_PRICE;
        }
    }

}
