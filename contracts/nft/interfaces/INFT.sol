// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../NFTStructs.sol";
import "../../common/interfaces/IERC721.sol";
import "../../common/interfaces/IERC721Receiver.sol";
import "../../common/interfaces/IERC721Metadata.sol";
import "../../common/interfaces/IERC721Mintable.sol";
import "../../common/interfaces/IERC165.sol";

interface INFTEvents {
    event ConfigUpdated();

    event LevelUpdated(uint256 tokenId, Level level);

    event NameSet(uint256 tokenId, string name);
}

interface INFTConfiguration {
    function updateConfig(NFTConfig calldata config) external;

    function getConfig() external view returns (NFTConfig memory);
}

interface INFTWithRarity {
    function getRarity(uint256 tokenId) external view returns (Rarity);

    function calculateRarityAndHashrate(
        uint256 blockNumber,
        uint256 id,
        address owner
    ) external view returns (Rarity, uint256);
}

interface INFTMayor {
    function batchMint(address owner, string[] calldata names) external returns (uint256[] memory tokenIds);

    function updateLevel(uint256 tokenId, Level level) external;

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner
    ) external;

    function getName(uint256 tokenId) external view returns (string memory);

    function getLevel(uint256 tokenId) external view returns (Level);

    function getHashrate(uint256 tokenId) external view returns (uint256);

    function getVotePrice(uint256 tokenId) external view returns (uint256);
}

interface INFT is IERC165, IERC721, IERC721Metadata, INFTConfiguration, INFTWithRarity, INFTMayor {}
