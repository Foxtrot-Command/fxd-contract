// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "contracts/financial/Foundation.sol";
import "contracts/financial/Antibot.sol";

/**
 *   @title FXD Token (Foxtrot Command)
 *   @author Michael Araque (@michyaraque)
 *   @notice A contract that manages a ERC20 token with initial setup for future Governance
 */

contract FoxtrotCommand is
    ERC20Burnable,
    ERC20Snapshot,
    Pausable,
    Foundation,
    Antibot
{
    uint256 private constant _TOKEN_SUPPLY = 215e6;
    mapping(address => bool) internal _liquidityPairs;

    event SecureTransferTokenFromContract(
        address from,
        address to,
        uint256 amount,
        string reason
    );

    constructor(address multisigAccount) ERC20("Foxtrot Command", "FXD") {
        Antibot.isAntibotEnabled = true;
        Foundation.isFoundationEnabled = true;

        Antibot.setCooldownExempt(multisigAccount, true);
        Foundation.setFoundationExempt(multisigAccount, true);

        Antibot.setCooldownExempt(address(this), true);
        Foundation.setFoundationExempt(address(this), true);

        // Deployer inmediately transfer ownership to multisigAccount
        transferOwnership(multisigAccount);

        _mint(address(this), _TOKEN_SUPPLY * 10**18); // 215M
    }

    /**
     * @dev This function uses the Ownable interface to allow only the owner to call it.
     * @notice This function is used to set a pair of addresses as a liquidity pair.
     * @param account Address to be parsed
     * @param status true/false to be enabled or disabled
     */
    function setLiquidityPair(address account, bool status)
        external
        authorized
        returns (bool)
    {
        _setLiquidityPair(account, status);
        return true;
    }

    /**
     * @notice This function is used to check if a pair of addresses is a liquidity pair.
     * @param account Address of the liquidity pair to check status
     */
    function isLiquidityPair(address account) external view returns (bool) {
        return _liquidityPairs[account];
    }

    /**
     * @notice This methods allows secure transfer from contract to address/contract
     * @param token       Address of the token contract
     * @param receiver    Address of the wallet that will receive the tokens
     * @param amount      Amount of tokens to be transfered
     * @param reason      Reason for withdrawal of tokens by the multisig
     */
    function secureTransfer(
        IERC20 token,
        address receiver,
        uint256 amount,
        string memory reason
    ) public authorized returns (bool) {
        _secureTransfer(token, receiver, amount, reason);
        return true;
    }

    /**
     * @notice This methods allows secure transfer from contract to addresses/contracts
     * @param token       Addresses of the token contract
     * @param receiver    Addresses of the wallet that will receive the tokens
     * @param amount      Amounts of tokens to be transfered
     * @param reason      Reasons for withdrawal of tokens by the multisig
     */
    function secureBatchTransfer(
        IERC20[] calldata token,
        address[] calldata receiver,
        uint256[] calldata amount,
        string[] memory reason
    ) external authorized returns (bool) {
        require(
            token.length == receiver.length &&
                token.length == amount.length &&
                token.length == reason.length,
            "FXD: data length mismatch"
        );
        for (uint256 i = 0; i < token.length; i++) {
            _secureTransfer(token[i], receiver[i], amount[i], reason[i]);
        }
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
        address addressToCooldown = Antibot._detectAddressToCooldown(
            _liquidityPairs[sender],
            sender,
            recipient
        );
        Antibot._isAvailableToTransact(addressToCooldown);

        if (!Foundation._isFoundationExempt[addressToCooldown]) {
            if (
                Foundation.isFoundationEnabled &&
                (_liquidityPairs[sender] || _liquidityPairs[recipient])
            ) {
                uint256 taxCalculation = Foundation.getFoundationFeeAmount(
                    amount
                );
                amount -= taxCalculation;
                super._transfer(
                    sender,
                    Foundation.foundationAddress,
                    taxCalculation
                );
            }
        }

        super._transfer(sender, recipient, amount);
    }

    /**
     * @notice This methods allows secure transfer from contract to address/contract
     * @param token       Address of the token contract
     * @param receiver    Address of the wallet that will receive the tokens
     * @param amount      Amount of tokens to be transfered
     * @param reason      Reason for withdrawal of tokens by the multisig
     */
    function _secureTransfer(
        IERC20 token,
        address receiver,
        uint256 amount,
        string memory reason
    ) private {
        require(
            token.balanceOf(address(this)) >= amount,
            "FXD: Unavailable amount."
        );
        token.transfer(receiver, amount);
        emit SecureTransferTokenFromContract(
            msg.sender,
            receiver,
            amount,
            reason
        );
    }

    /**
     * @notice This function is used to set a pair of addresses as a liquidity pair.
     * @param account Address to be parsed
     * @param status true/false to be enabled or disabled
     */
    function _setLiquidityPair(address account, bool status) private {
        _liquidityPairs[account] = status;
        Antibot.setCooldownExempt(account, status);
        Foundation.setFoundationExempt(account, status);
    }

    function pause() external authorized {
        _pause();
    }

    function unpause() external authorized {
        _unpause();
    }

    function snapshot() external authorized {
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
