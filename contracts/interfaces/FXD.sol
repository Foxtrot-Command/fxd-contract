// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFXD {
    function depositRemainder(uint256 _amount) external returns(bool);
    function availableRemainderTokens() external view returns(uint256);
}