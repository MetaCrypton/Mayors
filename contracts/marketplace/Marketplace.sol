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
    error SameAddress();
    error SameValue();
    error NotTradable();
    error AlreadyOwner();
    error NotOnSale();

    Lootbox internal _lootbox;
    NFT internal _nft;
    Token internal _paymentTokenPrimary;
    Token internal _paymentTokenSecondary;

    uint256 internal _lootboxPrice;

    mapping(address => bool) internal _eligibleForLootbox;
    mapping(bytes32 => uint256) internal _salePrice;

    constructor(
        address owner,
        address lootboxAddress,
        address nftAddress,
        address paymentTokenPrimary,
        address paymentTokenSecondary,
        uint256 price
    ) Ownable(owner) {
        _lootbox = Lootbox(lootboxAddress);
        _nft = NFT(nftAddress);
        _paymentTokenPrimary = Token(paymentTokenPrimary);
        _paymentTokenSecondary = Token(paymentTokenSecondary);
        _lootboxPrice = price;
        emit PaymentTokenPrimaryAddressSet(paymentTokenPrimary);
        emit PaymentTokenSecondaryAddressSet(paymentTokenSecondary);
        emit NFTAddressSet(nftAddress);
        emit LootboxAddressSet(lootboxAddress);
        emit LootboxPriceSet(price);
    }

    function setForSale(Item calldata item, uint256 price) external override {
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

        _paymentTokenSecondary.transferFrom(msg.sender, owner, price);
        IERC721(item.addr).transferFrom(owner, msg.sender, item.tokenId);
        emit ItemBought(item.addr, item.tokenId, price);
    }

    function buyLootbox() external override returns (uint256) {
        if (!_eligibleForLootbox[msg.sender]) revert NotEligible();

        _eligibleForLootbox[msg.sender] = false;

        uint256 id = _lootbox.mint(msg.sender);
        emit LootboxBought(msg.sender, address(_lootbox), id);

        _withdrawPayment();

        return id;
    }

    function setLootboxAddress(address lootboxAddress) external override isOwner {
        if (address(_lootbox) == lootboxAddress) revert SameAddress();
        _lootbox = Lootbox(lootboxAddress);
        emit LootboxAddressSet(lootboxAddress);
    }

    function setPaymentTokenPrimaryAddress(address paymentTokenAddress) external override isOwner {
        if (address(_paymentTokenPrimary) == paymentTokenAddress) revert SameAddress();
        _paymentTokenPrimary = Token(paymentTokenAddress);
        emit PaymentTokenPrimaryAddressSet(paymentTokenAddress);
    }

    function setPaymentTokenSecondaryAddress(address paymentTokenAddress) external override isOwner {
        if (address(_paymentTokenSecondary) == paymentTokenAddress) revert SameAddress();
        _paymentTokenSecondary = Token(paymentTokenAddress);
        emit PaymentTokenSecondaryAddressSet(paymentTokenAddress);
    }

    function setLootboxPrice(uint256 price) external override isOwner {
        if (_lootboxPrice == price) revert SameValue();
        _lootboxPrice = price;
        emit LootboxPriceSet(price);
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

    function getLootboxPrice() external view override returns (uint256) {
        return _lootboxPrice;
    }

    function getPaymentTokenPrimaryAddress() external view override returns (address) {
        return address(_paymentTokenPrimary);
    }

    function getPaymentTokenSecondaryAddress() external view override returns (address) {
        return address(_paymentTokenSecondary);
    }

    function getLootboxAddress() external view override returns (address) {
        return address(_lootbox);
    }

    function _withdrawPayment() internal {
        _paymentTokenPrimary.transferFrom(msg.sender, _owner, _lootboxPrice);
    }

    function _isTradableItem(address item) internal view returns (bool) {
        return item == address(_nft) || item == address(_lootbox);
    }
}
