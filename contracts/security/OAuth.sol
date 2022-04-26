// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract OAuth is AccessControl {

    address public owner;
    mapping (address => bool) internal _authorizations;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address multisigAddress) {
         _grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
         owner = multisigAddress;
    }

    /**
     * @notice A modifier that checks if the caller is authorized to call the function
     */
    modifier authorized() {
        _checkRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        _;
    }

    /**
     * @notice Check if address is owner
     * @param account Address to check ownership
     */
    function isOwner(address account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @notice Transfer ownership to new address. Caller must be owner. 
     *         Leaves old owner authorized
     * @param account New owner of the contract
     */
    function renounceOwnership(address account) external authorized() {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
        owner = address(0);
        emit OwnershipTransferred(account, address(0));
    }
}