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

    event UpdateFoundationConfig(uint256 newTaxValue);

    /**
     * @dev Calculates the fee based on the input `amount`
	 */
	function getFoundationFeeAmount(uint256 amount) internal view returns (uint256) {
		return (amount * tax) / 10000;
	}

    /**
	 * @dev Changes the game pool address `foundationVatAddress` to `newFoundationAddress`.
	 */
	function setFoundationAddress(address newFoundationAddress) external authorized() {
		foundationAddress = newFoundationAddress;
	}

    /**
     * @dev The new tax value must be on basis point (100 = 1%)
     */
    function setFoundationFee(uint256 newTaxValue) external authorized() {
        require(tax != newTaxValue, "FXD: New tax is the same");
        tax = newTaxValue;

        emit UpdateFoundationConfig(newTaxValue);
    }

}