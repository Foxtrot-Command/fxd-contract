// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "contracts/security/OAuth.sol";

abstract contract Antibot is OAuth {

    bool public isAntibotEnabled;
    uint256 public cooldownTimerInterval = 60;
    uint256 internal _maxPossibleCooldownInterval = 120;

    mapping (address => uint) internal _cooldownTimer;
    mapping (address => bool) internal _isCooldownExempt;

    event UpdateAntiBotConfig(bool cooldown, uint8 cooldownTime);

    function _detectAddressToCooldown(bool isSenderLiquidity, address sender, address recipient) internal pure returns(address) {
        return isSenderLiquidity ? recipient : sender;
    }

    /**
     * @notice Function used to track address buy cooldown
     * @param addr Address that send the transaction
     */
    function _isAvailableToTransact(address addr) internal {
        if(isAntibotEnabled && _cooldownTimer[addr] < block.timestamp) {
            _cooldownTimer[addr] = block.timestamp + cooldownTimerInterval;
        } else {
            revert("FXDGuard: wait between two tx");
        }
    }


    function setAntibotStatus() external authorized() {
        isAntibotEnabled = !isAntibotEnabled;
    }
    
    function setAntibotWaitTime(uint256 newWaitTime) external authorized() {
        require(newWaitTime <= _maxPossibleCooldownInterval, "FXDGuard: limit time exceed");
        cooldownTimerInterval = newWaitTime;
    }

    /**
     * @notice This method allow the authorized address to add/update cooldown exempt addresses
     * @param adr Address of the user
     * @param state Set true/false
     */
    function updateCooldownExempt(address adr, bool state) public authorized {
        _isCooldownExempt[adr] = state;
    }
}