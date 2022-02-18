// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./NFTStructs.sol";
import "../common/interfaces/IERC721.sol";
import "../common/interfaces/IERC721Receiver.sol";
import "../common/interfaces/IERC721Metadata.sol";
import "../common/interfaces/IERC721Mintable.sol";
import "../common/interfaces/IERC165.sol";

interface INFTFromLootbox {
    event LootboxAddressSet(address lootboxAddress);

    function setLootboxAddress(address lootboxAddress) external;

    function getLootboxAddress() external view returns (address);
}

interface INFTWithRarity {
    function getRarity(uint256 tokenId) external view returns (Rarity);

    function calculateRarity(
        uint blockNumber,
        uint256 id,
        address owner
    ) external view returns (Rarity);
}

interface INFT is IERC165, IERC721, IERC721Metadata, INFTFromLootbox, INFTWithRarity {}
