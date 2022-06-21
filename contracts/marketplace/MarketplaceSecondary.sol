// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IMarketplace.sol";
import "./common/MarketplaceErrors.sol";
import "./common/MarketplaceConstants.sol";
import "./common/MarketplaceStorage.sol";
import "../common/interfaces/IERC721.sol";

contract MarketplaceSecondary is IMarketplaceSecondary, IMarketplaceEvents, MarketplaceStorage {
    function setItemForSale(Item calldata item, uint256 price) external override {
        if (price < MarketplaceConstants.MIN_VALID_PRICE) revert MarketplaceErrors.NotValidPrice();
        if (!_isTradableItem(item.addr)) revert MarketplaceErrors.NotTradable();
        if (IERC721(item.addr).ownerOf(item.tokenId) != msg.sender) revert MarketplaceErrors.NotItemOwner();

        bytes32 id = keccak256(abi.encode(item));
        if (_itemSale[id].price == price) revert MarketplaceErrors.SameValue();

        _itemSale[id].price = price;
        _itemSale[id].seller = msg.sender;
        emit ItemPriceSet(item.addr, item.tokenId, price);
    }

    function removeItemFromSale(Item calldata item) external override {
        if (IERC721(item.addr).ownerOf(item.tokenId) != msg.sender) revert MarketplaceErrors.NotItemOwner();
        if (!_isTradableItem(item.addr)) revert MarketplaceErrors.NotTradable();

        bytes32 id = keccak256(abi.encode(item));
        if (_itemSale[id].price == 0 || _itemSale[id].seller == address(0)) revert MarketplaceErrors.NotOnSale();

        delete _itemSale[id];
        emit ItemPriceRemoved(item.addr, item.tokenId);
    }

    function buyItem(Item calldata item, uint256 price) external nonReentrant override {
        address owner = IERC721(item.addr).ownerOf(item.tokenId);
        if (owner == msg.sender) revert MarketplaceErrors.AlreadyOwner();
        if (!_isTradableItem(item.addr)) revert MarketplaceErrors.NotTradable();

        bytes32 id = keccak256(abi.encode(item));
        uint256 sellPrice = _itemSale[id].price;
        address seller = _itemSale[id].seller;
        if (sellPrice == 0 || seller == address(0)) revert MarketplaceErrors.NotOnSale();
        if (sellPrice != price) revert MarketplaceErrors.NotValidPrice();
        if (seller == msg.sender) revert MarketplaceErrors.NotValidBuyer();

        delete _itemSale[id];
        emit ItemBought(item.addr, item.tokenId, sellPrice);

        _payForItem(sellPrice, owner);

        IERC721(item.addr).transferFrom(owner, msg.sender, item.tokenId);
    }

    function getItemPrice(Item calldata item) external view override returns (uint256) {
        ItemSale storage itemSale = _itemSale[keccak256(abi.encode(item))];
        if (itemSale.price == 0 || itemSale.seller == address(0)) revert MarketplaceErrors.NotOnSale();
        return itemSale.price;
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
