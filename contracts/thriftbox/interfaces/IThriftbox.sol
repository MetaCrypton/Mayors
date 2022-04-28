// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "./IThriftboxLifecycle.sol";
import "./IThriftboxConfiguration.sol";
import "./IThriftboxEvents.sol";
import "../../common/interfaces/IERC721.sol";
import "../../common/interfaces/IERC721Receiver.sol";
import "../../common/interfaces/IERC721Metadata.sol";
import "../../common/interfaces/IERC721Mintable.sol";
import "../../common/interfaces/IERC165.sol";

interface IThriftbox is IThriftboxConfiguration, IThriftboxLifecycle,  IThriftboxEvents {}
