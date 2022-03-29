// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract OAuth {

    address internal _owner;
    mapping (address => bool) internal _authorizations;

    event OwnershipTransferred(address owner);

    constructor() {
        _owner = msg.sender;
        _authorizations[_owner] = true;
    }

    /**
     * @notice Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "OAuth: only owner"); _;
    }

    /**
     * @notice Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(_authorizations[msg.sender] == true, "OAuth: you're not authorized"); _;
    }

    /**
     * @notice Authorize address. Owner only
     */
    function authorize(address adr) external onlyOwner {
        _authorizations[adr] = true;
    }

    /**
     * @notice Remove address' authorization. Owner only
     */
    function unauthorize(address adr) external onlyOwner {
        _authorizations[adr] = false;
    }

    /**
     * @notice Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    /**
     * @notice Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return _authorizations[adr];
    }

    /**
     * @notice Transfer ownership to new address. Caller must be owner. 
     *         Leaves old owner authorized
     */
    function transferOwnership(address payable adr) external onlyOwner {
        _owner = adr;
        _authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }
}