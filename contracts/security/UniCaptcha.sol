// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/security/OAuth.sol";

contract UniCaptcha is OAuth {

    bool public canUseSecurePurchase = false;

    mapping(address => bool) internal isSecured;

    function checkAddressApproved() external view returns(bool) {
        return isSecured[msg.sender];
    }

    function approveSecureTransaction() external {
        require(canUseSecurePurchase, "FXD: secure its not needed");
        isSecured[msg.sender] = true;
    }

    function disableSecurePurchase() public authorized() {
        require(canUseSecurePurchase, "FXD: Not allowed");
        canUseSecurePurchase = false;
    }

}