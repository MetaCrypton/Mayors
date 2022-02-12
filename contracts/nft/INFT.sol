// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/interfaces/IERC721.sol";
import "../common/interfaces/IERC721Receiver.sol";
import "../common/interfaces/IERC721Metadata.sol";
import "../common/interfaces/IERC721Mintable.sol";
import "../common/interfaces/IERC165.sol";

interface INFT is IERC165, IERC721, IERC721Mintable, IERC721Metadata {
    event LootboxAddressSet(address lootboxAddress);

    /**
     * @dev Mints several `tokenId`. See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function batchMint(address owner, uint256 number) external returns (uint256[] memory tokenIds);

    function setLootboxAddress(address lootboxAddress) external;

    function getLootboxAddress() external view returns (address);
}
