// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "contracts/security/OAuth.sol";

/**
    @title Foundation Fee
    @author Michael Araque
    @notice This is an extension of FXD Token that is a bunch of functions to retrieve the foundation fee
 */
 
abstract contract Foundation is OAuth {

    uint256 public tax = 100;
    address public foundationAddress;
    bool public isFoundationEnabled;

    mapping (address => bool) internal _isFoundationExempt;

    event UpdateFoundationTax(uint256 newTaxValue);
    event UpdateFoundationAddres(address newAddress);

    /**
     * @notice
     */
    function setFoundationStatus() external authorized() {
        isFoundationEnabled = !isFoundationEnabled;
    }

    /**
     * @dev Calculates the fee based on the input `amount` in basis
	 */
	function getFoundationFeeAmount(uint256 amount) internal view returns (uint256) {
		return (amount * tax) / 10000;
	}

    /**
	 * @dev Changes the game pool address `foundationAddress` to `newFoundationAddress`.
	 */
	function setFoundationAddress(address newFoundationAddress) external authorized {
        require(newFoundationAddress != foundationAddress, "FXD: Address is the same");
		foundationAddress = newFoundationAddress;
        emit UpdateFoundationAddres(foundationAddress);
	}

    /**
     * @dev The new tax value must be on basis point (100 = 1%)
     */
    function setFoundationFee(uint256 newTaxValue) external authorized {
        require(tax != newTaxValue, "FXD: New tax is the same");
        tax = newTaxValue;

        emit UpdateFoundationTax(newTaxValue);
    }

    /**
     * @notice This function is used to check if the address is exempt from foundation
     * @param addr Address of the wallet to be checked
     */
    function isExemptFromFoundation(address addr) public view returns(bool) {
        return _isFoundationExempt[addr];
    }

    /**
     * @notice This method allow the authorized address to add/update foundation exempt addresses
     * @param addr Address of wallted to update
     * @param state Set true/false
     */
    function setFoundationExempt(address addr, bool state) public authorized() {
        _isFoundationExempt[addr] = state;
    }

}