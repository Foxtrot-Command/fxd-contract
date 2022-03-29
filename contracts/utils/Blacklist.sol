// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Blacklist {

    enum BlacklistType {
        DISABLED,
        ENABLED
    }

    mapping(address => uint8) isBlacklisted;

    modifier onlyNotBlacklisted() {
       require(isBlacklisted[msg.sender] == uint8(BlacklistType.DISABLED), "FXD: Your address is blacklisted.");
       _;
    }

    function blacklistAddress(address account) public returns (bool) {
        require(isBlacklisted[account] == uint8(BlacklistType.ENABLED), "FXD: Address already blacklisted");
        isBlacklisted[account] = uint8(BlacklistType.ENABLED);
        return true;
    }

    function unblacklistAddress(address account) public returns (bool) {
        require(isBlacklisted[account] == uint8(BlacklistType.ENABLED), "FXD: Address not in blacklist");
        isBlacklisted[account] = uint8(BlacklistType.DISABLED);
        return true;
    }

    function checkAddressInBlacklist(address account) public view returns (bool) {
        return isBlacklisted[account] == uint8(BlacklistType.ENABLED) ? true : false;
    }
}