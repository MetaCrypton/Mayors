// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

interface ITestNumber {
    function setNumber(uint256 testNumber_) external;

    function getNumber() external view returns (uint256);
}

interface ITestNumberInc is ITestNumber {
    function incNumber() external;
}
