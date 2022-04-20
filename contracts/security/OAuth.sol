// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract OAuth is AccessControl {

    address internal _owner;
    mapping (address => bool) internal _authorizations;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address multisigAddress) {
         _grantRole(DEFAULT_ADMIN_ROLE, multisigAddress);
    }

    /**
     * @notice Modifier to require caller to be authorized
     */
    modifier authorized() {
        _checkRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        _;
    }

    /**
     * @notice Method to allow authorized role to grand role to an address
     */
    function setRoleTo(bytes32 _role, address _to) external authorized() {
        _grantRole(_role, _to);
    }

    /**
     * @notice Check if address is owner
     * @param account Address to check ownership
     */
    function isOwner(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @notice Transfer ownership to new address. Caller must be owner. 
     *         Leaves old owner authorized
     */
    function renounceOwnership(bytes32 role, address account) external authorized() {
        _revokeRole(role, account);
        emit OwnershipTransferred(account, address(0));
    }
}