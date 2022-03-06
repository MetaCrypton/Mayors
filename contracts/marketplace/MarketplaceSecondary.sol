// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./interfaces/IMarketplace.sol";
import "./common/MarketplaceErrors.sol";
import "./common/MarketplaceConstants.sol";
import "./common/MarketplaceStorage.sol";
import "../common/interfaces/IERC721.sol";

contract MarketplaceSecondary is IMarketplaceSecondary, IMarketplaceEvents, MarketplaceStorage {
    function setForSale(Item calldata item, uint256 price) external override {
        if (price < MarketplaceConstants.MIN_VALID_PRICE) revert MarketplaceErrors.NotValidPrice();
        if (!_isTradableItem(item.addr)) revert MarketplaceErrors.NotTradable();
        if (IERC721(item.addr).ownerOf(item.tokenId) != msg.sender) revert MarketplaceErrors.NotItemOwner();

        bytes32 id = keccak256(abi.encode(item));
        if (_salePrice[id] == price) revert MarketplaceErrors.SameValue();

        _salePrice[id] = price;
        emit SalePriceSet(item.addr, item.tokenId, price);
    }

    function buyItem(Item calldata item) external override {
        address owner = IERC721(item.addr).ownerOf(item.tokenId);
        if (owner == msg.sender) revert MarketplaceErrors.AlreadyOwner();

        bytes32 id = keccak256(abi.encode(item));
        uint256 price = _salePrice[id];
        if (price == 0) revert MarketplaceErrors.NotOnSale();

        _salePrice[id] = 0;
        emit ItemBought(item.addr, item.tokenId, price);

        _payForItem(price, owner);

        IERC721(item.addr).transferFrom(owner, msg.sender, item.tokenId);
    }

    function getItemPrice(Item calldata item) external view override returns (uint256) {
        uint256 price = _salePrice[keccak256(abi.encode(item))];
        if (price == 0) revert MarketplaceErrors.NotOnSale();
        return price;
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
