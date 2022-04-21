// SPDX-License-Identifier: Apache 2.0
// Copyright © 2022 Artem Belozerov. All rights reserved.
pragma solidity ^0.8.0;

import "../../common/interfaces/IERC20.sol";
import "../../common/interfaces/IERC20Burnable.sol";
import "../../common/interfaces/IERC20Metadata.sol";
import "../../common/interfaces/IERC20Mintable.sol";
import "../../common/interfaces/IERC165.sol";

interface IVoucherERC20 is IERC165, IERC20, IERC20Metadata, IERC20Mintable, IERC20Burnable {}
