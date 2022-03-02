// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../InventoryStructs.sol";

interface IInventoryEvents {
    event ConfigUpdated();

    event DepositEther(address indexed sender, uint256 amount);
    event WithdrawEther(address indexed recipient, uint256 amount);

    event DepositERC20(address indexed sender, address indexed token, uint256 amount);
    event WithdrawERC20(address indexed recipient, address indexed token, uint256 amount);

    event DepositERC721(address indexed sender, address indexed token, uint256 indexed tokenId);
    event WithdrawERC721(address indexed recipient, address indexed token, uint256 indexed tokenId);

    event AssetAdded(uint256 indexed id, AssetType indexed assetType, bytes data);
    event AssetUpdated(uint256 indexed id, bytes data);
    event AssetRemoved(uint256 indexed id);
}

interface IInventoryConfiguration {
    function updateConfig(InventoryConfig calldata config) external;

    function getConfig() external view returns (InventoryConfig memory);
}

interface IInventoryEther {
    function depositEther() external payable;

    function withdrawEther(address recipient, uint256 amount) external;

    function getEtherBalance() external view returns (uint256);
}

interface IInventoryERC20 {
    function depositERC20(
        address from,
        address token,
        uint256 amount
    ) external;

    function withdrawERC20(
        address recipient,
        address token,
        uint256 amount
    ) external;

    function getERC20s(uint256 startIndex, uint256 number) external view returns (ERC20Struct[] memory);

    function getERC20Balance(address token) external view returns (uint256);
}

interface IInventoryERC721 {
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

    function getERC721s(uint256 startIndex, uint256 number) external view returns (ERC721Struct[] memory);

    function isERC721Owner(address token, uint256 tokenId) external view returns (bool);
}

interface IInventory is IInventoryEvents, IInventoryConfiguration, IInventoryEther, IInventoryERC20, IInventoryERC721 {}
