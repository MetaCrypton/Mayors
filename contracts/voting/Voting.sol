// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "../common/ownership/Ownable.sol";
import "../nft/NFT.sol";
import "../token/Token.sol";
import "./IVoting.sol";
import "./VotingConstants.sol";
import "./VotingStructs.sol";
import "./VotingErrors.sol";

contract Voting is IVoting, Ownable {
    NFT public mayor;
    Token public votesToken;
    Token public voucherToken;

    uint256 internal constant VOTING_DURATION = 86400; //24 hours in seconds
    uint256 internal constant GOVERNANCE_DURATION = 86400 * 5; //5 days in seconds
    uint256 internal constant CLAIMING_DURATION = 86400; //24 hours in seconds

    uint256 internal constant PRIZE_RATE = 87;
    // uint256 internal constant REWARD_POOL_RATE = 10;
    uint256 internal constant REWARD_BURN_RATE = 3;

    // amount of votes for 1 citizen, 18 digits
    uint256 public votesPerCitizen = 1 ether;

    // city id => City
    mapping(uint256 => City) internal _cities;
    // region id => Region
    mapping(uint256 => Region) internal _regions;
    // regionId => [city id]
    mapping(uint256 => uint256[]) internal _regionToCities;

    // city id => Mayor
    mapping(uint256 => uint256) public cityToMayor;

    // TODO: change bool to the timestamp for calculating Monument reward? 
    // owner address => city id => Building => 0: not exists, >0: season number +1
    mapping(address => mapping(uint256 => mapping(Building => uint256))) internal _ownerToBuildings;

    // owner address => [Win]
    mapping(address => Win[]) internal _ownerToWins;

    // city id => Nominee
    mapping(uint256 => Nominee[]) internal _cityToNominees;

    constructor(
        NFT mayorNFT,
        Token votesToken_,
        Token voucherToken_,
        address owner
    ) {
        mayor = mayorNFT;
        votesToken = votesToken_;
        voucherToken = voucherToken_;
        _owner = owner;
    }

    function changeVotesPerCitizen(uint256 amount) external override isOwner {
        if (amount == 0) revert VotingErrors.IncorrectValue();
        uint256 oldAmount = votesPerCitizen;
        votesPerCitizen = amount;

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
                active: true,
                bank: 0
            });
            _cities[newCity.id] = city;
            _regionToCities[regionId].push(newCity.id);
            cityIds[i] = newCity.id;
            emit CitiesAdded(regionId, cityIds);
        }
        _startVoting(regionId);
    }

    function changeCityVotePrice(uint256 cityId, uint256 newPrice) external override isOwner {
        if (newPrice == 0) revert VotingErrors.IncorrectValue();
        City memory city = _cities[cityId];
        if (city.population == 0) revert VotingErrors.IncorrectValue();
        _cities[cityId].votePrice = newPrice;

        emit VotePriceUpdated(cityId, city.votePrice, newPrice);
    }

    function addBuilding(
        uint256 cityId,
        uint256 mayorId,
        Building newBuilding
    ) external override {
        if(!_isGoverningPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        if(
            mayor.ownerOf(mayorId) != msg.sender ||
            cityToMayor[cityId] != mayorId
        ) revert VotingErrors.WrongMayor();
        uint256 buildingPrice = _getBuildingPrice(newBuilding);
        if(voucherToken.balanceOf(msg.sender) < buildingPrice) revert VotingErrors.InsufficientBalance();
        if(_ownerToBuildings[msg.sender][cityId][newBuilding] > 0) revert VotingErrors.BuildingDuplicate();
        _ownerToBuildings[msg.sender][cityId][newBuilding] = _seasonNumber(_cities[cityId].regionId) + 1;
        emit BuildingAdded(newBuilding, cityId, msg.sender);
        voucherToken.transferFrom(msg.sender, address(this), buildingPrice);
    }

    function nominate(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external override {
        if (!_cities[cityId].active) revert VotingErrors.InactiveObject();
        if (!_isVotingPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        if(mayor.ownerOf(mayorId) != msg.sender) revert VotingErrors.WrongMayor();
        // get the price of those votes
        uint256 priceInVotes = _calculateVotesPrice(mayorId, cityId, votes);
        // check if msg.sender has enough Token balance: balanceOf(msg.sender) >= votes
        if (votesToken.balanceOf(msg.sender) < priceInVotes) revert VotingErrors.InsufficientBalance();
        // save user vote info
        _cityToNominees[cityId].push(Nominee({ mayorId: mayorId, votes: votes }));
        _cities[cityId].bank += votes;
        emit CandidateAdded(mayorId, cityId, votes);
        // transfer the "votes" amount from user to reward pool
        votesToken.transferFrom(msg.sender, address(this), priceInVotes);
    }

    function chooseWinner(uint256 regionId) external override {
        if (!_regions[regionId].active) revert VotingErrors.InactiveObject();
        if (_isVotingPeriod(regionId)) revert VotingErrors.IncorrectPeriod();
        uint256[] memory citiesIds = _regionToCities[regionId];
        uint256 winnerId = 0;
        for (uint256 i = 0; i < citiesIds.length; i++) {
            if (_cities[citiesIds[i]].active) {
                Nominee[] memory nominees = _cityToNominees[citiesIds[i]];
                if (_cities[citiesIds[i]].bank > 0) {
                    winnerId = _calculateWinner(regionId, citiesIds[i], nominees);
                    cityToMayor[citiesIds[i]] = winnerId;
                    // TODO: add burnAmount
                    // _calculatePrizeToBurn(citiesIds[i]);
                    _ownerToWins[mayor.ownerOf(winnerId)].push(Win({
                        cityId: citiesIds[i], bank: _cities[citiesIds[i]].bank,
                        season: _seasonNumber(regionId) + 1, claimed: false
                    }));
                    _cities[citiesIds[i]].bank = 0;
                }
            }
        }

        emit WinnersChosen(regionId);
    }

    function updateCities(uint256[] calldata citiesIds, bool isOpen) external override isOwner {
        for(uint256 i = 0; i < citiesIds.length; i++) {
            _cities[citiesIds[i]].active = isOpen;
        }

        emit CitiesUpdated(citiesIds, isOpen);
    }

    function updateRegions(uint256[] calldata regionsIds, bool isOpen) external override isOwner {
        for(uint256 i = 0; i < regionsIds.length; i++) {
            _regions[regionsIds[i]].active = isOpen;
        }

        emit RegionsUpdated(regionsIds, isOpen);
    }

    function claimPrize(uint256 regionId) external override {
        if (!_isRewardPeriod(regionId)) revert VotingErrors.IncorrectPeriod();
        uint256 totalPrize = 0;
        Win[] memory ownerWins = _ownerToWins[msg.sender];
        // uint256 totalBurn = 0;
        for (uint256 i = 0; i < ownerWins.length; i++) {
            if(!ownerWins[i].claimed) {
                totalPrize += _calculatePrizeToUser(
                    ownerWins[i].cityId, msg.sender, ownerWins[i].season, ownerWins[i].bank
                );
                _ownerToWins[msg.sender][i].claimed = true;
                // totalBurn += _ownerToRewards[msg.sender][cityIds[i]].burnAmount;
            }
        }
        // send tokens to the winner
        if (totalPrize > 0) {
            votesToken.transfer(msg.sender, totalPrize);
            emit PrizeClaimed(msg.sender, totalPrize);
        }
        // TODO: 3% needs to be burned
        // votesToken.burn(totalBurn);
    }

    function calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external view override returns(uint256) {
        return _calculateVotesPrice(mayorId, cityId, votes);
    }

    function calculatePrize(uint256 cityId) external view override returns(uint256 prize) {
        uint256 season = _seasonNumber(_cities[cityId].regionId) + 1;
        if (!_isRewardPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        prize = 0;
        Win[] memory ownerWins = _ownerToWins[mayor.ownerOf(cityToMayor[cityId])];
        for (uint256 i = ownerWins.length; i > 0; i--) {
            if (ownerWins[i-1].season == season && ownerWins[i-1].cityId == cityId) {
                prize =  _calculatePrizeToUser(
                    cityId, mayor.ownerOf(cityToMayor[cityId]), season, ownerWins[i-1].bank
                );
                break;
            }
        }
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

    function _isVotingPeriod(uint256 regionId) internal view returns(bool ok) {
        // solhint-disable-next-line not-rely-on-time
        ok = ((block.timestamp - _regions[regionId].startVotingTimestamp) %
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
        if(
            votes > ((_cities[cityId].population * votesPerCitizen / 1 ether) - _cities[cityId].bank)
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
        return 100 - mayor.getVoteDiscount(nftId) - _getBuildingsDiscount(cityId, account);
    }

    function _calculateWinner(
        uint256 regionId,
        uint256 cityId,
        Nominee[] memory nominees
    ) internal view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number), regionId, cityId)));
        uint256 winnerRate = random % _cities[cityId].bank;
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

    function _calculatePrizeToBurn(uint256 cityId) internal view returns(uint256) {
        if (!_isRewardPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
        return _cities[cityId].bank * REWARD_BURN_RATE / 100;
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
