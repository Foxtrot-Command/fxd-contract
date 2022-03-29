// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/utils/OAuth.sol";

contract Security is OAuth {

    bool public canUseSecurePurchase = true;
    bool public isCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 60;

    mapping(address => bool) internal isSecured;
    mapping (address => uint) internal _cooldownTimer;
    mapping (address => bool) internal _isCooldownExempt;

    event UpdateAntiBotConfig(bool cooldown, uint8 cooldownTime);

    /** SECURE UNICAPTCHA */

    function approveSecureTransaction() public {
        require(canUseSecurePurchase, "FXD: secure its not needed");
        isSecured[msg.sender] = true;
    }

    function disableSecurePurchase() public authorized() {
        require(canUseSecurePurchase, "FXD: Not allowed");
        canUseSecurePurchase = false;
    }

    /** SECURE ANTIBOT */

    /**
     * @notice This method allow the authorized address to add/update cooldown exempt addresses
     * @param adr Address of the user
     * @param state Set true/false
     */
    function updateCooldownExempt(address adr, bool state) public authorized {
        _isCooldownExempt[adr] = state;
    }

    /**
     * @notice This method allow the authorized addres to change
     *         the anti-whale status
     * @param cooldownState Cooldown state
     * @param cooldownInterval Cooldown interval in seconds | Default: 60
     */
    function setAntiBotConfig(bool cooldownState, uint8 cooldownInterval) public authorized {
        isCooldownEnabled = cooldownState;
        cooldownTimerInterval = cooldownInterval;
        emit UpdateAntiBotConfig(cooldownState, cooldownInterval);
    }

    /**
     * @notice Function used to track address buy cooldown
     * @param addr Address that send the transaction
     */
    function _checkBuyCooldownTime(address addr) internal {
        if(isCooldownEnabled && _cooldownTimer[addr] < block.timestamp) {
            _cooldownTimer[addr] = block.timestamp + cooldownTimerInterval;
        } else {
            revert("FXDGuard: wait between two tx");
        }
    }
}