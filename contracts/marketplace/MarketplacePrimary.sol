// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IMarketplace.sol";
import "./common/MarketplaceErrors.sol";
import "./common/MarketplaceStorage.sol";
import "../common/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MarketplacePrimary is IMarketplacePrimary, IMarketplaceEvents, Ownable, MarketplaceStorage {
    function buyLootboxMP(uint256 index, bytes32[] calldata merkleProof) external override returns (uint256) {
        if (_lootboxesLeft == 0) revert MarketplaceErrors.OutOfStock();
        if (!verifyMerkleProof(index, msg.sender, merkleProof)) revert MarketplaceErrors.NotInWhiteList();
        if (_lootboxesBought[msg.sender] >= _config.lootboxesPerAddress) revert MarketplaceErrors.TooManyLootboxes();

        _lootboxesLeft--;
        _lootboxesBought[msg.sender]++;

        uint256 id = _config.lootbox.mint(_seasonURI, msg.sender);
        emit LootboxBought(msg.sender, address(_config.lootbox), id);

        _config.paymentTokenPrimary.transferFrom(msg.sender, _config.feeAggregator, _config.lootboxPrice);

        return id;
    }

    function buyLootbox() external override returns (uint256) {
        if (_lootboxesLeft == 0) revert MarketplaceErrors.OutOfStock();
        if (!_whiteListForLootbox[msg.sender]) revert MarketplaceErrors.NotInWhiteList();
        if (_lootboxesBought[msg.sender] >= _config.lootboxesPerAddress) revert MarketplaceErrors.TooManyLootboxes();

        _lootboxesLeft--;
        _lootboxesBought[msg.sender]++;

        uint256 id = _config.lootbox.mint(_seasonURI, msg.sender);
        emit LootboxBought(msg.sender, address(_config.lootbox), id);

        _config.paymentTokenPrimary.transferFrom(msg.sender, _config.feeAggregator, _config.lootboxPrice);

        return id;
    }

    function sendLootboxes(uint256 number, address recipient) external override isOwner {
        if (_lootboxesLeft < number) revert MarketplaceErrors.OutOfStock();

        _lootboxesLeft -= number;
        _config.lootbox.batchMint(number, _seasonURI, recipient);
    }

    function addToWhiteList(address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool whiteList = _whiteListForLootbox[participants[i]];
            if (!whiteList) {
                _whiteListForLootbox[participants[i]] = true;
                emit AddedToWhiteList(participants[i]);
            }
        }
    }

    function removeFromWhiteList(address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool whiteList = _whiteListForLootbox[participants[i]];
            if (whiteList) {
                _whiteListForLootbox[participants[i]] = false;
                emit RemovedFromWhiteList(participants[i]);
            }
        }
    }

    function isInWhiteList(address participant) external view override returns (bool) {
        return _whiteListForLootbox[participant];
    }

    function verifyMerkleProof(
        uint256 index,
        address account,
        bytes32[] memory merkleProof
    ) public view override returns (bool) {
        bytes32 node = _node(index, account);
        return MerkleProof.verify(merkleProof, _config.merkleRoot, node);
    }

    function _node(uint256 index, address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account));
    }
}
