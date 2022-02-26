// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./IMarketplace.sol";
import "../lootbox/Lootbox.sol";
import "../nft/NFT.sol";
import "../token/Token.sol";
import "../common/ownership/Ownable.sol";

contract Marketplace is IMarketplace, Ownable {
    error NotEligible();
    error TooManyLootboxes();
    error SameValue();
    error NotTradable();
    error AlreadyOwner();
    error NotOnSale();
    error SameConfig();
    error OutOfStock();
    error NotValidPrice();

    uint256 internal constant MIN_VALID_PRICE = 100 wei;

    MarketplaceConfig internal _config;

    mapping(address => bool) internal _eligibleForLootbox;
    mapping(address => uint256) internal _lootboxesBought;
    mapping(bytes32 => uint256) internal _salePrice;

    constructor(MarketplaceConfig memory config, address owner) Ownable(owner) {
        _config = config;
    }

    function setForSale(Item calldata item, uint256 price) external override {
        if (price < MIN_VALID_PRICE) revert NotValidPrice();
        if (!_isTradableItem(item.addr)) revert NotTradable();
        if (IERC721(item.addr).ownerOf(item.tokenId) != msg.sender) revert NotOwner();

        bytes32 id = keccak256(abi.encode(item));
        if (_salePrice[id] == price) revert SameValue();

        _salePrice[id] = price;
        emit SalePriceSet(item.addr, item.tokenId, price);
    }

    function buyItem(Item calldata item) external override {
        address owner = IERC721(item.addr).ownerOf(item.tokenId);
        if (owner == msg.sender) revert AlreadyOwner();

        bytes32 id = keccak256(abi.encode(item));
        uint256 price = _salePrice[id];
        if (price == 0) revert NotOnSale();

        _salePrice[id] = 0;
        emit ItemBought(item.addr, item.tokenId, price);

        _payForItem(price, owner);

        IERC721(item.addr).transferFrom(owner, msg.sender, item.tokenId);
    }

    function buyLootbox() external override returns (uint256) {
        if (_config.lootboxesCap == 0) revert OutOfStock();
        if (!_eligibleForLootbox[msg.sender]) revert NotEligible();
        if (_lootboxesBought[msg.sender] >= _config.lootboxesPerAddress) revert TooManyLootboxes();

        _config.lootboxesCap--;
        _lootboxesBought[msg.sender]++;
        _eligibleForLootbox[msg.sender] = false;

        uint256 id = _config.lootbox.mint(msg.sender);
        emit LootboxBought(msg.sender, address(_config.lootbox), id);

        _config.paymentTokenPrimary.transferFrom(msg.sender, _config.feeAggregator, _config.lootboxPrice);

        return id;
    }

    function updateConfig(MarketplaceConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(_config))) revert SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function addToEligible(address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool eligible = _eligibleForLootbox[participants[i]];
            if (!eligible) {
                _eligibleForLootbox[participants[i]] = true;
                emit AddedToEligible(participants[i]);
            }
        }
    }

    function removeFromEligible(address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool eligible = _eligibleForLootbox[participants[i]];
            if (eligible) {
                _eligibleForLootbox[participants[i]] = false;
                emit RemovedFromEligible(participants[i]);
            }
        }
    }

    function getItemPrice(Item calldata item) external view override returns (uint256) {
        uint256 price = _salePrice[keccak256(abi.encode(item))];
        if (price == 0) revert NotOnSale();
        return price;
    }

    function isEligible(address participant) external view override returns (bool) {
        return _eligibleForLootbox[participant];
    }

    function getConfig() external view override returns (MarketplaceConfig memory) {
        return _config;
    }

    function _payForItem(uint256 price, address owner) internal {
        _config.paymentTokenSecondary.transferFrom(msg.sender, address(this), price);
        uint256 fee = price / 100;
        _config.paymentTokenSecondary.transfer(_config.feeAggregator, fee);
        _config.paymentTokenSecondary.transfer(owner, price - fee);
    }

    function _isTradableItem(address item) internal view returns (bool) {
        return item == address(_config.nft) || item == address(_config.lootbox);
    }
}
