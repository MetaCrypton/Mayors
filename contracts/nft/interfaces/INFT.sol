// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "./INFTMayor.sol";
import "./INFTConfiguration.sol";
import "./INFTEvents.sol";
import "./INFTInventories.sol";
import "../../common/interfaces/IERC721.sol";
import "../../common/interfaces/IERC721Receiver.sol";
import "../../common/interfaces/IERC721Metadata.sol";
import "../../common/interfaces/IERC721Mintable.sol";
import "../../common/interfaces/IERC165.sol";

interface INFT is IERC165, IERC721, IERC721Metadata, INFTConfiguration, INFTMayor, INFTEvents, INFTInventories {}
