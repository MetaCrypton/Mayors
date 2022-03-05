// SPDX-License-Identifier: Apache 2.0
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.

pragma solidity ^0.8.0;

import "./ITestNumber.sol";

contract TestNumber is ITestNumber {
    uint256 internal _testNumber;

    function setNumber(uint256 testNumber) external override {
        _testNumber = testNumber;
    }

    function getNumber() external view override returns (uint256) {
        return _testNumber;
    }
}

contract TestNumberInc is ITestNumberInc, TestNumber {
    function incNumber() external override {
        _testNumber += 1;
    }
}
