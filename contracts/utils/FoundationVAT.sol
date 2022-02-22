// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "contracts/utils/Security.sol";

contract FoundationVAT is OAuth {

    uint256 public tax = 100;
    address public foundationVatAddress;

    /**
     * @dev Calculates the fee based on the input `amount`
	 */
	function getFoundationVatFeeAmount(uint256 amount) internal view returns (uint256) {
		return (amount * tax) / 10000;
	}

    /**
	 * @dev Changes the game pool address `foundationVatAddress` to `newFoundationVatAddress`.
	 */
	function setFoundationVatAddress(address newFoundationVatAddress) external authorized() {
		foundationVatAddress = newFoundationVatAddress;
	}

    /**
     * @dev The new tax value must be on basis point (100 = 1%)
     */
    function setFoundationVat(uint256 newTaxValue) external authorized() {
        require(tax != newTaxValue, "FXD: New tax is the same");
        tax = newTaxValue;
    }

}