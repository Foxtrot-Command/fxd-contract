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

    /**
     * @notice This function is used to detect the address that will be put on cooldown
     * @param isSenderLiquidity Check if sender comes from liquidity pool
     * @param sender Address of the sender of the transaction
     * @param recipient Address of the transaction receiver
     */
    function _detectAddressToCooldown(bool isSenderLiquidity, address sender, address recipient) internal pure returns(address) {
        return isSenderLiquidity ? recipient : sender;
    }

    /**
     * @notice Function used to track address transaction
     * @param addr Address that send the transaction
     */
    function _isAvailableToTransact(address addr) internal {
        if(isAntibotEnabled) {
            
            if(!_isCooldownExempt[addr]) {
                if(_cooldownTimer[addr] < block.timestamp) {
                    _cooldownTimer[addr] = block.timestamp + cooldownTimerInterval;
                } else {
                    revert("FXDGuard: wait between two tx");
                }
            }
        }         
    }

    /**
     * @notice This function is used to enable/disable the antibot system
     */
    function setAntibotStatus() external authorized() {
        isAntibotEnabled = !isAntibotEnabled;
    }
    
    /**
     * @notice This method allows to change the wait time of the antibot system
     * @param newWaitTime the input should be in seconds
     */
    function setAntibotWaitTime(uint256 newWaitTime) external authorized() {
        require(newWaitTime <= _maxPossibleCooldownInterval, "FXDGuard: limit time exceed");
        cooldownTimerInterval = newWaitTime;
    }

    /**
     * @notice This function is used to check if the address is exempt from cooldown
     * @param addr Address of the wallet to be checked
     */
    function isExemptFromCooldown(address addr) public view returns(bool) {
        return _isCooldownExempt[addr];
    }

    /**
     * @notice This method allow the authorized address to add/update cooldown exempt addresses
     * @param addr Address of wallted to update
     * @param state Set true/false
     */
    function setCooldownExempt(address addr, bool state) public authorized() {
        _isCooldownExempt[addr] = state;
    }
}