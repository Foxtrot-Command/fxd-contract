// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OAuth is Ownable, AccessControl {

    bytes32 public constant SUPREME_ROLE = keccak256("SUPREME_ROLE");

    uint256 constant internal _MAX_USABLE_FUNCTION_ATTEMPS = 1;
    mapping(bytes32 => uint256) internal _useFunctionAttemps;

    constructor() {
        _grantRole(SUPREME_ROLE, msg.sender);
    }

    /**
     * @notice Renounce the `role` from the `account`
     * @param role The role to be revoked
     * @param account The account to be revoked
     */
    function renounceRole(bytes32 role, address account) public override {
        super.renounceRole(role, account);
    }

    /**
     * @notice A modifier that checks if the caller is authorized to call the function
     */
    modifier authorized() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner"); 
        _;
    }

    /**
     * @notice A modifier that checks executions attemps to the function
     */
    modifier attemp(string memory functionName) {
        uint256 attemps = OAuth._useFunctionAttemps[keccak256(abi.encode(functionName))];
        require(attemps < OAuth._MAX_USABLE_FUNCTION_ATTEMPS, "FXDGuard: Exceed attempts");
        _;
        attemps++;
    }
}