// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./InventoryStructs.sol";
import "../../common/ownership/OwnableStorage.sol";
import "../../common/proxy/ProxyStorage.sol";
import "../../nft/NFT.sol";

contract InventoryStorage is OwnableStorage, ProxyStorage {
    bytes32 internal constant PROXY_ID = keccak256("Inventory");

    address internal _upgradesRegistry;

    NFT internal _nftContract;
    uint256 internal _nftId;

    AssetsSet internal _assetsSet;
}
