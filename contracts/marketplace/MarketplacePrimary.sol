// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IMarketplace.sol";
import "./common/MarketplaceErrors.sol";
import "./common/MarketplaceStorage.sol";
import "../common/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MarketplacePrimary is IMarketplacePrimary, IMarketplaceEvents, Ownable, MarketplaceStorage {
    function buyLootboxMP(
        uint256 seasonId,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external override returns (uint256) {
        Season storage season = _verifySeason(seasonId, 1);

        // Verify merkle proof
        if (!verifyMerkleProof(seasonId, index, msg.sender, merkleProof)) revert MarketplaceErrors.NotInMerkleTree();

        return _buyLootbox(seasonId, season);
    }

    function buyLootbox(uint256 seasonId) external override returns (uint256) {
        Season storage season = _verifySeason(seasonId, 1);

        if (!_whiteList[seasonId][msg.sender]) revert MarketplaceErrors.NotInWhiteList();

        return _buyLootbox(seasonId, season);
    }

    function sendLootboxes(
        uint256 seasonId,
        uint256 number,
        address recipient
    ) external override isOwner {
        Season storage season = _verifySeason(seasonId, number);

        _seasons[seasonId].lootboxesNumber -= number;
        _lootboxesBought[seasonId][msg.sender] += number;
        emit LootboxesSentInBatch(seasonId, recipient, address(_config.lootbox), number);

        _config.lootbox.batchMint(number, season.uri, recipient, season.lootboxesUnlockTimestamp);
    }

    function addToWhiteList(uint256 seasonId, address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool whiteList = _whiteList[seasonId][participants[i]];
            if (!whiteList) {
                _whiteList[seasonId][participants[i]] = true;
                emit AddedToWhiteList(seasonId, participants[i]);
            }
        }
    }

    function removeFromWhiteList(uint256 seasonId, address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool whiteList = _whiteList[seasonId][participants[i]];
            if (whiteList) {
                _whiteList[seasonId][participants[i]] = false;
                emit RemovedFromWhiteList(seasonId, participants[i]);
            }
        }
    }

    function isInWhiteList(uint256 seasonId, address participant) external view override returns (bool) {
        return _whiteList[seasonId][participant];
    }

    function verifyMerkleProof(
        uint256 seasonId,
        uint256 index,
        address account,
        bytes32[] memory merkleProof
    ) public view override returns (bool) {
        bytes32 node = _node(index, account);
        return MerkleProof.verify(merkleProof, _seasons[seasonId].merkleRoot, node);
    }

    function _buyLootbox(uint256 seasonId, Season storage season) internal returns (uint256) {
        _seasons[seasonId].lootboxesNumber--;
        _lootboxesBought[seasonId][msg.sender]++;

        uint256 id = _config.lootbox.mint(season.uri, msg.sender, season.lootboxesUnlockTimestamp);
        emit LootboxBought(seasonId, msg.sender, address(_config.lootbox), id);

        _config.paymentTokenPrimary.transferFrom(msg.sender, _config.feeAggregator, season.lootboxPrice);

        return id;
    }

    function _getSeason(uint256 seasonId) internal view returns (Season storage) {
        if (seasonId > _seasons.length - 1) revert MarketplaceErrors.UnexistingSeason();
        return _seasons[seasonId];
    }

    function _verifySeason(uint256 seasonId, uint256 lootboxes) internal view returns (Season storage) {
        Season storage season = _getSeason(seasonId);

        // solhint-disable not-rely-on-time
        if (season.startTimestamp > block.timestamp) revert MarketplaceErrors.SeasonNotStarted();
        if (season.endTimestamp > 0 && season.endTimestamp <= block.timestamp)
            revert MarketplaceErrors.SeasonFinished();
        // solhint-enable not-rely-on-time
        if (season.lootboxesNumber < lootboxes) revert MarketplaceErrors.LootboxesEnded();
        if (season.lootboxesPerAddress < _lootboxesBought[seasonId][msg.sender] + lootboxes)
            revert MarketplaceErrors.TooManyLootboxesPerAddress();

        return season;
    }

    function _node(uint256 index, address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account));
    }
}
