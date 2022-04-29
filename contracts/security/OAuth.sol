// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OAuth is Ownable {

    /**
     * @notice A modifier that checks if the caller is authorized to call the function
     */
    modifier authorized() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner"); 
        _;
    }
}