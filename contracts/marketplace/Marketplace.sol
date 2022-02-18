// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./IMarketplace.sol";
import "../lootbox/Lootbox.sol";
import "../token/Token.sol";
import "../common/ownership/Ownable.sol";

contract Marketplace is IMarketplace, Ownable {
    error NotEligible();
    error SameAddress();
    error SameValue();

    Lootbox internal _lootbox;
    Token internal _paymentToken;
    uint256 internal _lootboxPrice;
    mapping(address => bool) internal _eligibleForLootbox;

    constructor(
        address owner,
        address lootboxAddress,
        address paymentToken,
        uint256 price
    ) Ownable(owner) {
        _lootbox = Lootbox(lootboxAddress);
        _paymentToken = Token(paymentToken);
        _lootboxPrice = price;
        emit PaymentTokenAddressSet(paymentToken);
        emit LootboxAddressSet(lootboxAddress);
        emit LootboxPriceSet(price);
    }

    function buyLootbox() external override returns (uint256) {
        if (!_eligibleForLootbox[msg.sender]) revert NotEligible();

        _eligibleForLootbox[msg.sender] = false;

        uint256 id = _lootbox.mint(msg.sender);
        emit LootboxBought(msg.sender, address(_lootbox), id);

        _withdrawPayment();

        return id;
    }

    function _withdrawPayment() internal {
        _paymentToken.transferFrom(msg.sender, _owner, _lootboxPrice);
    }

    function setLootboxAddress(address lootboxAddress) external override isOwner {
        if (address(_lootbox) == lootboxAddress) revert SameAddress();
        _lootbox = Lootbox(lootboxAddress);
        emit LootboxAddressSet(lootboxAddress);
    }

    function setPaymentTokenAddress(address paymentTokenAddress) external override isOwner {
        if (address(_paymentToken) == paymentTokenAddress) revert SameAddress();
        _paymentToken = Token(paymentTokenAddress);
        emit PaymentTokenAddressSet(paymentTokenAddress);
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

    function isEligible(address participant) external view override returns (bool) {
        return _eligibleForLootbox[participant];
    }

    function getLootboxPrice() external view override returns (uint256) {
        return _lootboxPrice;
    }

    function getPaymentTokenAddress() external view override returns (address) {
        return address(_paymentToken);
    }

    function getLootboxAddress() external view override returns (address) {
        return address(_lootbox);
    }
}
