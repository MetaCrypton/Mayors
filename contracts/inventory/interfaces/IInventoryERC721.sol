// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./IInventoryAsset.sol";
import "./IInventoryEventsERC721.sol";

interface IInventoryERC721 is IInventoryAsset, IInventoryEventsERC721 {
    function depositERC721(
        address from,
        address token,
        uint256 tokenId
    ) external;

    function withdrawERC721(
        address recipient,
        address token,
        uint256 tokenId
    ) external;

    function isERC721Owner(address token, uint256 tokenId) external view returns (bool);

    function getERC721s(uint256 startIndex, uint256 number) external view returns (ERC721Struct[] memory);
}
