// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./ILootboxConfiguration.sol";
import "./ILootboxLifecycle.sol";
import "./ILootboxEvents.sol";
import "../../common/interfaces/IERC721.sol";
import "../../common/interfaces/IERC721Receiver.sol";
import "../../common/interfaces/IERC721Metadata.sol";
import "../../common/interfaces/IERC165.sol";

interface ILootbox is IERC165, IERC721, IERC721Metadata, ILootboxConfiguration, ILootboxLifecycle, ILootboxEvents {}
