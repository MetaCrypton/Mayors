// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./VotingStructs.sol";

interface IVoting {
    event CitiesAdded(uint256 indexed regionId, uint256[] newCities);
    event VotePriceUpdated(uint256 indexed cityId, uint256 oldPrice, uint256 newPrice);
    event VotingStarted(uint256 indexed regionId, uint256 endVotingTimestamp);
    event BuildingAdded(Building newBuilding, uint256 indexed cityId, uint256 indexed mayorId, address indexed owner);
    event CandidateAdded(uint256 indexed mayorId, uint256 indexed cityId, uint256 votes);
    event CityUpdated(uint256 indexed cityId, bool isOpen);
    event PrizeClaimed(address indexed account, uint256 amount);
    event VotesPerCitizenUpdated(uint256 oldAmount, uint256 amount);

    function transferTokens(address recipient) external;

    function changeVotesPerCitizen(uint256 amount) external;

    function addCities(uint256 regionId, NewCity[] calldata newCities) external;

    function changeCityVotePrice(uint256 cityId, uint256 newPrice) external;

    function addBuilding(
        uint256 cityId,
        Building newBuilding
    ) external;

    function nominate(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external;

    function updateCities(uint256[] calldata citiesIds, bool isOpen) external;

    function claimPrizes(PrizeClaim[] calldata claims) external;

    function getWinner(uint256 cityId, uint256 season) external view returns(uint256);

    function calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external view returns(uint256);

    function calculatePrizeToUser(uint256 cityId, uint256 season, address account) external view returns(uint256);
}
