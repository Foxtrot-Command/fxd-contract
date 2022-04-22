// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "contracts/financial/Foundation.sol";
import "contracts/financial/Antibot.sol";

/**
    @title FXD Token (Foxtrot Command)
    @author Michael Araque
    @notice A contract that manages a ERC20 token with initial setup for future Governance
 */

contract FoxtrotCommand is
    ERC20Burnable,
    ERC20Snapshot,
    Pausable,
    Foundation,
    Antibot 
{

    uint256 constant private _TOKEN_SUPPLY = 215e6;
    mapping(address => bool) internal _liquidityPairs;

    event WithdrawTokensFromMainContract(address from, address to, uint256 amount, string reason);

    constructor(address multisigAddress) ERC20("Foxtrot Command", "FXD") OAuth(multisigAddress) {
        uint256 supply = _TOKEN_SUPPLY * 10**18; // 215M

        Antibot.isAntibotEnabled = true;
        Foundation.isFoundationEnabled = true;
        _mint(multisigAddress, supply);
    }

    /**
     * @notice This function is used to set a pair of addresses as a liquidity pair.
     * @param account Address to be parsed
     * @param status true/false to be enabled or disabled
     */
    function setLiquidityPair(address account, bool status) external authorized() returns(bool) {
        _liquidityPairs[account] = status;
        return true;
    }

    /**
     * @notice This function is used to check if a pair of addresses is a liquidity pair.
     * @param account Address of the liquidity pair to check status
     */
    function isLiquidityPair(address account) external view returns(bool) {
        return _liquidityPairs[account];
    }

    /**
     * @notice This methods allows secure transfer from contract to address/contract
     * @param token       Address of the token contract
     * @param receiver    Address of the wallet that will receive the tokens
     * @param amount      Amount of tokens to be transfered
     */
    function secureWithdraw(
        IERC20 token,
        address receiver,
        uint256 amount
    ) public authorized() returns (bool) {
        require(token != IERC20(address(this)), "FXD: Cannot withdraw FXD Tokens");
        require(token.balanceOf(address(this))>= amount, "FXD: Unavailable amount");
        token.transfer(receiver, amount);
        return true;
    }

    /**
     * @notice This method is overridden because it is to implement the Anti-bot system and 
     *         the Foundation's system
     * @param sender Address of the transfer request
     * @param recipient Address of the transfer receiver
     * @param amount Amount in wei to be transferred
     */
    function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal override {
      
        address addressToCooldown = Antibot._detectAddressToCooldown(_liquidityPairs[sender], sender, recipient);
        Antibot._isAvailableToTransact(addressToCooldown);

        if(!Foundation._isFoundationExempt[addressToCooldown]) {
            if(Foundation.isFoundationEnabled && 
                (_liquidityPairs[sender] || _liquidityPairs[recipient])) {
                uint256 taxCalculation = Foundation.getFoundationFeeAmount(amount);
                amount -= taxCalculation; 
                super._transfer(sender, Foundation.foundationAddress, taxCalculation);
            }
        }

        super._transfer(sender, recipient, amount);
    }

    function pause() external authorized() {
        _pause();
    }

    function unpause() external authorized() {
        _unpause();
    }

    function snapshot() external authorized() {
        _snapshot();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._afterTokenTransfer(from, to, amount);
    }

}
