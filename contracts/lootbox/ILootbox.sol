// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/interfaces/IERC721.sol";
import "../common/interfaces/IERC721Receiver.sol";
import "../common/interfaces/IERC721Metadata.sol";
import "../common/interfaces/IERC721Mintable.sol";
import "../common/interfaces/IERC165.sol";

interface ILootbox is IERC165, IERC721, IERC721Mintable, IERC721Metadata {
    event NFTAddressSet(address nftAddress);
    event MarketplaceAddressSet(address marketplaceAddress);
    event NumberInLootboxSet(uint256 number);

    function reveal(uint256 tokenId) external returns (uint256[] memory tokenIds);

    function setNFTAddress(address token) external;

    function setMarketplaceAddress(address marketplace) external;

    function setNumberInLootbox(uint256 number) external;

    function getNFTAddress() external view returns (address);

    function getMarketplaceAddress() external view returns (address);

    function getNumberInLootbox() external view returns (uint256);
}
