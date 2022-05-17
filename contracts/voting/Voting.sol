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
    uint256 internal constant VOTING_DURATION = 1 days;
    uint256 internal constant GOVERNANCE_DURATION = 6 days;

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

    // owner address => city id => Building => 0: not exists, >0: season number +1
    mapping(address => mapping(uint256 => mapping(Building => uint256))) internal _ownerToBuildings;

    // owner address => city id => season => prize is claimed
    mapping(address => mapping(uint256 => mapping(uint256 => BuildingClaim))) internal _ownerBuildingClaimed;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) internal _ownerElectionClaimed;

    // city id => season id => Nominee[]
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
            if (newCity.population == 0) revert VotingErrors.IncorrectValue();
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
        City storage city = _cities[cityId];
        if (city.population == 0) revert VotingErrors.UnknownCity();
        if (_isVotingPeriod(city.regionId)) revert VotingErrors.IncorrectPeriod();
        if (newPrice == 0) revert VotingErrors.IncorrectValue();

        uint256 oldPrice = city.votePrice;
        city.votePrice = newPrice;
        emit VotePriceUpdated(cityId, oldPrice, newPrice);
    }

    function addBuilding(
        uint256 cityId,
        Building newBuilding
    ) external override {
        if (_cities[cityId].population == 0) revert VotingErrors.UnknownCity();
        if(!_isGoverningPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();

        uint256 season = _seasonNumber(_cities[cityId].regionId);
        uint256 winnerMayorId = _calculateWinner(season, cityId);
        if(_mayor.ownerOf(winnerMayorId) != msg.sender) revert VotingErrors.NotWinner();

        uint256 buildingPrice = _getBuildingPrice(newBuilding);
        if(_ownerToBuildings[msg.sender][cityId][newBuilding] > 0) revert VotingErrors.BuildingDuplicate();
        _ownerToBuildings[msg.sender][cityId][newBuilding] = season;

        emit BuildingAdded(newBuilding, cityId, winnerMayorId, msg.sender);
        _voucherToken.transferFrom(msg.sender, address(this), buildingPrice);
    }

    function nominate(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external override {
        City storage city = _cities[cityId];
        if (city.population == 0) revert VotingErrors.UnknownCity();
        if (!city.active) revert VotingErrors.InactiveObject();
        if (!_isVotingPeriod(city.regionId)) revert VotingErrors.IncorrectPeriod();
        if (_mayor.ownerOf(mayorId) != msg.sender) revert VotingErrors.WrongMayor();

        uint256 seasonNumber = _seasonNumber(city.regionId);
        uint256 citizenVotes = city.population * _votesPerCitizen / 10 ** _voteDigits;
        if (votes > (citizenVotes - _getBank(cityId, seasonNumber))) revert VotingErrors.VotesBankExceeded();

        // get the price of those votes
        uint256 priceInVotes = _calculateVotesPrice(mayorId, cityId, votes);

        // save user vote info
        _cityToNominees[cityId][seasonNumber].push(Nominee({ mayorId: mayorId, votes: votes }));
        emit CandidateAdded(mayorId, cityId, votes);

        // transfer the "votes" amount from user to reward pool
        _voteToken.transferFrom(msg.sender, address(this), priceInVotes);
    }

    function updateCities(uint256[] calldata citiesIds, bool isOpen) external override isOwner {
        for(uint256 i = 0; i < citiesIds.length; i++) {
            uint256 cityId = citiesIds[i];
            if (_isVotingPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
            _cities[cityId].active = isOpen;
            emit CityUpdated(cityId, isOpen);
        }
    }

    function claimPrizes(
        uint256 cityId,
        uint256[] calldata electionSeasonIds,
        uint256[] calldata buildingSeasonIds
    ) external override {
        uint256 currentSeason = _seasonNumber(_cities[cityId].regionId);

        (uint256 prize, uint256 burnPrize) = _claimElectionPrizes(msg.sender, cityId, electionSeasonIds, currentSeason);
        prize += _claimBuildingPrizes(msg.sender, cityId, buildingSeasonIds, currentSeason);

        // send tokens to the winner
        emit PrizeClaimed(msg.sender, prize, burnPrize);
        _voteToken.transfer(msg.sender, prize);

        // 3% needs to be burned
        _voteToken.burn(address(this), burnPrize);
    }

    function getCurrentSeason(uint256 cityId) external view override returns (uint256) {
        return _seasonNumber(_cities[cityId].regionId);
    }

    function getWinner(uint256 cityId, uint256 season) external view override returns(uint256) {
        return _calculateWinner(season, cityId);
    }

    function calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external view override returns(uint256) {
        if (_cities[cityId].population == 0) revert VotingErrors.UnknownCity();
        return _calculateVotesPrice(mayorId, cityId, votes);
    }

    function getUnclaimedElectionPrizes(
        address account,
        uint256 cityId,
        uint256 startIndex,
        uint256 endIndex
    ) external view override returns (bool[] memory) {
        bool[] memory seasonIds = new bool[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (_ownerElectionClaimed[account][cityId][i]) continue;
            seasonIds[i] = true;
        }
        return seasonIds;
    }

    function getUnclaimedBuildings(
        address account,
        uint256 cityId,
        uint256 startIndex,
        uint256 endIndex
    ) external view override returns (bool[] memory) {
        bool[] memory seasonIds = new bool[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            if (_ownerBuildingClaimed[account][cityId][i].isClaimed) continue;
            seasonIds[i] = true;
        }
        return seasonIds;
    }

    function getElectionPrizes(
        uint256 cityId,
        uint256[] calldata seasonIds
    ) external view override returns (uint256) {
        uint256 totalPrize = 0;
        uint256 seasonsLength = seasonIds.length;
        for (uint256 i = 0; i < seasonsLength; i++) {
            totalPrize += _calculateElectionPrize(cityId, seasonIds[i]);
        }
        return totalPrize;
    }

    function getBuildingPrizes(
        address account,
        uint256 cityId,
        uint256[] calldata seasonIds,
        uint256 currentSeason
    ) external view override returns (uint256) {
        uint256 totalPrize = 0;
        uint256 seasonsLength = seasonIds.length;
        for (uint256 i = 0; i < seasonsLength; i++) {
            totalPrize += _calculateBuildingPrize(account, cityId, seasonIds[i], currentSeason);
        }
        return totalPrize;
    }

    function _claimElectionPrizes(
        address account,
        uint256 cityId,
        uint256[] calldata seasonIds,
        uint256 currentSeason
    ) internal returns (uint256, uint256){
        uint256 totalPrize = 0;
        uint256 totalBurn = 0;

        uint256 seasonsLength = seasonIds.length;
        for (uint256 i = 0; i < seasonsLength; i++) {
            uint256 season = seasonIds[i];
            if (season == 0 || season >= currentSeason) revert VotingErrors.IncorrectPeriod();
            if (!_isWinner(account, cityId, season)) revert VotingErrors.NotWinner();

            if (_ownerElectionClaimed[account][cityId][season]) revert VotingErrors.AlreadyClaimed();
            _ownerElectionClaimed[account][cityId][season] = true;

            totalPrize += _calculateElectionPrize(cityId, season);
            totalBurn += _calculatePrizeToBurn(cityId, season);
        }

        return (totalPrize, totalBurn);
    }

    function _claimBuildingPrizes(
        address account,
        uint256 cityId,
        uint256[] calldata seasonIds,
        uint256 currentSeason
    ) internal returns (uint256){
        uint256 totalPrize = 0;

        uint256 seasonsLength = seasonIds.length;
        for (uint256 i = 0; i < seasonsLength; i++) {
            uint256 season = seasonIds[i];
            if (season == 0 || season >= currentSeason) revert VotingErrors.IncorrectPeriod();
            if (!_isWinner(account, cityId, season)) revert VotingErrors.NotWinner();

            if (_ownerBuildingClaimed[account][cityId][season].isClaimed) revert VotingErrors.AlreadyClaimed();
            _ownerBuildingClaimed[account][cityId][season].isClaimed = true;

            totalPrize += _calculateBuildingPrize(account, cityId, season, currentSeason);
        }

        return totalPrize;
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
        return ((block.timestamp - _regions[
            regionId].startVotingTimestamp) /
            (VOTING_DURATION + GOVERNANCE_DURATION)) + 1;
    }

    function _isVotingPeriod(uint256 regionId) internal view returns(bool) {
        // solhint-disable-next-line not-rely-on-time
        return ((block.timestamp - _regions[regionId].startVotingTimestamp) %
            (VOTING_DURATION + GOVERNANCE_DURATION)) < VOTING_DURATION;
    }

    function _isGoverningPeriod(uint256 regionId) internal view returns(bool) {
        // solhint-disable-next-line not-rely-on-time
        return ((block.timestamp - _regions[regionId].startVotingTimestamp) %
            (VOTING_DURATION + GOVERNANCE_DURATION)) > VOTING_DURATION;
    }

    function _calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) internal view returns(uint256) {
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

    function _isWinner(
        address account,
        uint256 cityId,
        uint256 season
    ) internal view  returns (bool) {
        return _mayor.ownerOf(_calculateWinner(season, cityId)) == account;
    }

    function _calculateWinner(
        uint256 season,
        uint256 cityId
    ) internal view returns(uint256) {
        uint256 bank = _getBank(cityId, season);
        if (bank == 0) revert VotingErrors.IncorrectValue();

        uint256 random = uint256(keccak256(abi.encodePacked(season, cityId)));
        uint256 winnerRate = random % bank;
        uint256 votesCounter = 0;

        Nominee[] storage nominees = _cityToNominees[cityId][season];
        uint256 nomineesLength = nominees.length;
        for (uint256 i = 0; i < nomineesLength; i++) {
            votesCounter += nominees[i].votes;
            if (winnerRate < votesCounter) {
                return nominees[i].mayorId;
            }
        }

        // it will never be reached
        return nominees[nomineesLength - 1].mayorId;
    }

    function _calculateBuildingPrize(
        address account,
        uint256 cityId,
        uint256 currentSeason,
        uint256 season
    ) internal view returns (uint256) {
        Building building = _ownerBuildingClaimed[account][cityId][season].building;

        uint256 bank = _getBank(cityId, season);
        if (building == Building.Monument && season + 4 >= currentSeason) {
            bank += _getBank(cityId, season + 1);
            bank += _getBank(cityId, season + 2);
            bank += _getBank(cityId, season + 3);
        }
        return bank * _getBuildingRate(building) / 100;
    }

    function _calculateElectionPrize(uint256 cityId, uint256 season) internal view returns (uint256) {
        return _getBank(cityId, season) * PRIZE_RATE / 100;
    }

    function _calculatePrizeToBurn(uint256 cityId, uint256 season) internal view returns(uint256) {
        return _getBank(cityId, season) * REWARD_BURN_RATE / 100;
    }

    function _getBank(uint256 cityId, uint256 season) internal view returns (uint256) {
        uint256 bank = 0;

        Nominee[] storage nominees = _cityToNominees[cityId][season];
        uint256 nomineesLength = nominees.length;
        for (uint256 i = 0; i < nomineesLength; i++) {
            bank += nominees[i].votes;
        }
        return bank;
    }

    function _getBuildingRate(Building building) internal pure returns(uint8) {
        if (building == Building.Bank) {
            return VotingConstants.GOVERNANCE_RATE_BANK;
        } else if (building == Building.Factory) {
            return VotingConstants.GOVERNANCE_RATE_FACTORY;
        } else if (building == Building.Stadium) {
            return VotingConstants.GOVERNANCE_RATE_STADIUM;
        } else if (building == Building.Monument) {
            return VotingConstants.GOVERNANCE_RATE_MONUMENT;
        } else {
            return 0;
        }
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
