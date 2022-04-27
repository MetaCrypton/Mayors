// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./VotingStructs.sol";

interface IVoting {
    event CitiesAdded(uint256 regionId, uint256[] newCities);
    event VotePriceUpdated(uint256 cityId, uint256 oldPrice, uint256 newPrice);
    event VotingStarted(uint256 regionId, uint256 endVotingTimestamp);
    event BuildingAdded(Building newBuilding, uint256 cityId, address owner);
    event CandidateAdded(uint256 mayorId, uint256 cityId, uint256 votes);
    event CitiesUpdated(uint256[] closedCities, bool isOpen);
    event RegionsUpdated(uint256[] closedRegions, bool isOpen);
    event Winners(uint256 regionId, uint256[] winners);
    event VotesPerCitizenUpdated(uint256 oldAmount, uint256 amount);

    function changeVotesPerCitizen(uint256 amount) external;

    function addCities(uint256 regionId, NewCity[] calldata newCities) external;

    function changeCityVotePrice(uint256 cityId, uint256 newPrice) external;

    function startVoting(uint256 regionId) external;

    function addBuilding(
        uint256 cityId,
        uint256 mayorId,
        Building newBuilding
    ) external;

    function nominate(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external;

    function chooseWinner(uint256 regionId) external;

    function updateCities(uint256[] calldata citiesIds, bool isOpen) external;

    function updateRegions(uint256[] calldata regionsIds, bool isOpen) external;

    function claimPrize(uint256[] calldata cityIds) external;

    function savePrizeInfo(uint256 cityId) external;

    function trensferRewards(address account, uint256 amountVotes, uint256 amountVouchers) external; 

    function calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external view returns(uint256);

    function calculatePrize(uint256 cityId) external view returns(uint256);
}
