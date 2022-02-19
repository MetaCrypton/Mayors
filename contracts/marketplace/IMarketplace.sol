// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./MarketplaceStructs.sol";

interface IMarketplace {
    event PaymentTokenPrimaryAddressSet(address paymentToken);

    event PaymentTokenSecondaryAddressSet(address paymentToken);

    event LootboxAddressSet(address lootboxAddress);

    event NFTAddressSet(address nftAddress);

    event LootboxPriceSet(uint256 lootboxPrice);

    event AddedToEligible(address participant);

    event RemovedFromEligible(address participant);

    event LootboxBought(address buyer, address lootboxAddress, uint256 lootboxId);

    event SalePriceSet(address addr, uint256 tokenId, uint256 price);

    event ItemBought(address addr, uint256 tokenId, uint256 price);

    function setForSale(Item calldata item, uint256 price) external;

    function buyItem(Item calldata item) external;

    function buyLootbox() external returns (uint256);

    function setLootboxAddress(address lootboxAddress) external;

    function setPaymentTokenPrimaryAddress(address paymentTokenAddress) external;

    function setPaymentTokenSecondaryAddress(address paymentTokenAddress) external;

    function setLootboxPrice(uint256 price) external;

    function addToEligible(address[] calldata participants) external;

    function removeFromEligible(address[] calldata participants) external;

    function isEligible(address participant) external view returns (bool);

    function getLootboxPrice() external view returns (uint256);

    function getPaymentTokenPrimaryAddress() external view returns (address);

    function getPaymentTokenSecondaryAddress() external view returns (address);

    function getLootboxAddress() external view returns (address);

    function getItemPrice(Item calldata item) external view returns (uint256);
}
