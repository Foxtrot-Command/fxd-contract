// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "contracts/utils/OAuth.sol";

contract Antibot is OAuth {

    bool public isAntibotEnabled;
    uint256 public transactionCooldown = 60;
    mapping(address => uint256) public timeTransactionTracker;


    function isAvailableToTransact(address addr) internal view returns (bool) {
        if(isAntibotEnabled) {
            return block.timestamp - timeTransactionTracker[addr] < transactionCooldown;
        }
        return true;
    }

    function setAntibotStatus() external authorized() {
        isAntibotEnabled = !isAntibotEnabled;
    }
    
    function setAntibotWaitTime(uint256 newWaitTime) external authorized() {
        transactionCooldown = newWaitTime;
    }
}