// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "contracts/financial/Foundation.sol";
import "contracts/financial/Antibot.sol";
import "hardhat/console.sol";

/**
    @title FXD Token (Foxtrot Command)
    @author Michael Araque
    @notice A contract that manages a ERC20 token with initial setup for future Governance
 */

contract FoxtrotCommand is
    ERC20Burnable,
    Pausable,
    Foundation,
    Antibot
{

    mapping(address => bool) internal _liquidityPairs;

    constructor(
        uint256 _supply) ERC20("Foxtrot Command", "FXD") {
        uint256 supply = _supply * 10**18;

        _mint(address(this), supply);
    }

    function updateLiquidityPairs(address addr, bool status) external authorized() returns(bool) {
        _liquidityPairs[addr] = status;
        return true;
    }

    function getStatusOfLiquidityPair(address addr) external view returns(bool) {
        return _liquidityPairs[addr];
    }

    /**
        @notice This method allow the role TREASURY_MANAGER to transfer specific amount 
                of non FXD Tokens to a specific address manually (normally are garbage tokens)
        @param _token       Address of the token contract
        @param _receiver    Address of the wallet that will receive the tokens
        @param _amount      Amount of tokens to be transfered
     */
    function withdraw(
        address _token,
        address _receiver,
        uint256 _amount
    ) public authorized() returns (bool) {
        //require(_token != address(this), "FXD: You can't withdraw FXD");
        IERC20(_token).transfer(_receiver, _amount);
        return true;
    }

    function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal override {
      
        address addressToCooldown = Antibot._detectAddressToCooldown(_liquidityPairs[sender], sender, recipient);
        Antibot._isAvailableToTransact(addressToCooldown);

        if(_liquidityPairs[sender] || _liquidityPairs[recipient]) {
            uint256 taxCalculation = Foundation.getFoundationFeeAmount(amount);
            amount -= taxCalculation; 
            super._transfer(sender, Foundation.foundationAddress, taxCalculation);
        }

        super._transfer(sender, recipient, amount);
    }

    // The following functions are overrides required by Solidity.

    function pause() public authorized() {
        _pause();
    }

    function unpause() public authorized() {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20) {
        super._burn(account, amount);
    }
}
