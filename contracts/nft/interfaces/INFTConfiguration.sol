// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
pragma solidity ^0.8.0;

import "../common/NFTStructs.sol";

interface INFTConfiguration {
    function updateConfig(NFTConfig calldata config) external;

    function getConfig() external view returns (NFTConfig memory);
}
