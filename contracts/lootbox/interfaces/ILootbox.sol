// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../LootboxStructs.sol";
import "../../common/interfaces/IERC721.sol";
import "../../common/interfaces/IERC721Receiver.sol";
import "../../common/interfaces/IERC721Metadata.sol";
import "../../common/interfaces/IERC165.sol";

interface ILootboxEvents {
    event ConfigUpdated();
}

interface ILootboxConfiguration {
    function updateConfig(LootboxConfig calldata config) external;

    function getConfig() external view returns (LootboxConfig memory);
}

interface ILootboxLifecycle {
    function mint(address owner) external returns (uint256 tokenId);

    function reveal(uint256 tokenId, string[] memory names) external returns (uint256[] memory tokenIds);

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner
    ) external;
}

interface ILootbox is IERC165, IERC721, IERC721Metadata, ILootboxConfiguration, ILootboxLifecycle, ILootboxEvents {}
