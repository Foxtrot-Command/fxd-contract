// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/utils/Security.sol";
import "contracts/utils/FoundationVAT.sol";
import "contracts/utils/Antibot.sol";
import "hardhat/console.sol";
/**
    @title FXD Token (Foxtrot Command)
    @author Michael Araque
    @notice A contract that manages a ERC20 token with initial setup for future Governance
 */

contract FoxtrotCommand is
    ERC20Burnable,
    Pausable,
    FoundationVAT,
    Antibot,
    Security
{
    using Address for address;

    /**
     * Treasury setup
     */

    uint256 public treasuryFee;
    address public treasuryAddress;

    /**
     * Remainder balances setup
     * this balance come from sales where the allocation was not completely selled
     */

    uint256 public totalMintedTokens;

    mapping(address => bool) internal _liquidityPairs;

    /**
     * Business Logic tokenomics allowed names, address and amount
     */

    struct AllowedContracts {
        string name;
        bytes32 encodedName;
        address contractAddress;
        uint256 amount;
        bool isAmountAllowed;
    }

    string[] private allowedTokenomicNames;
    mapping(string => AllowedContracts) private allowedContract;

    event BusinessLogic(
        address _executor,
        address _receiverContract,
        string _tokenomicName,
        uint256 _amount
    );

    constructor(
        uint256 _supply,
        string[] memory _tokenomicNames,
        uint256[] memory _tokenomicAmounts
    ) ERC20("Foxtrot Command", "FXD") {
        uint256 supply = _supply * 10**18;

        _mint(address(this), supply);

        totalMintedTokens = supply;
        initializeAllowedContracts(_tokenomicNames, _tokenomicAmounts);
        treasuryFee = 20;
    }

    /**
       @notice This methods initialize the array of allowed Tokenomic <=> Contracts
       @param tokenomicNames Array of available tokenomic names
       @param tokenomicAmounts Array of available tokenomic amounts
     */
    function initializeAllowedContracts(
        string[] memory tokenomicNames,
        uint256[] memory tokenomicAmounts
    ) internal {
        for (uint256 i = 0; i < tokenomicNames.length; i++) {
            bytes32 name = keccak256(bytes(tokenomicNames[i]));
            allowedContract[tokenomicNames[i]] = AllowedContracts({
                name: tokenomicNames[i],
                encodedName: name,
                contractAddress: address(0x0),
                amount: tokenomicAmounts[i],
                isAmountAllowed: true
            });
            allowedTokenomicNames.push(tokenomicNames[i]);
        }
    }

    /**
       @return string[] Returns array of valid Tokenomic Names
     */
    function getAllowedTokenomicNames() public view returns (string[] memory) {
        return allowedTokenomicNames;
    }

    /**
       @param tokenomicName   Tokenomic valid name
       @return name
       @return encodedName
       @return contractAddress
       @return amount
     */
    function getAllowedContractData(string calldata tokenomicName)
        public
        view
        returns (
            string memory name,
            bytes32 encodedName,
            address contractAddress,
            uint256 amount
        )
    {
        AllowedContracts memory currentContract = allowedContract[
            tokenomicName
        ];

        name = currentContract.name;
        encodedName = currentContract.encodedName;
        contractAddress = currentContract.contractAddress;
        amount = currentContract.amount;
    }

    /**
        @notice This function allow the person with TOKEN_MANAGER role to set an address 
                to the selected tokenomic name
        @param tokenomicName Tokenomic available name selected
        @param contractAddress Address of the contract
     */
    function setAddressOfAllowedContract(
        string memory tokenomicName,
        address contractAddress
    ) public authorized() {
        require(contractAddress.isContract(), "FXD: Is not a contract");
        allowedContract[tokenomicName].contractAddress = contractAddress;
    }

    /**
       @notice This function is used for safe transfer token between business contracts
               without using raw wallets, this method only allows to transfer between 
               valid contract Address and valid amounts
       @param tokenomicName Tokenomic available name selected
       @return bool
     */
    function safeTransferBusinessTokens(string calldata tokenomicName)
        public
        authorized()
        returns (bool)
    {
        AllowedContracts storage currentContract = allowedContract[
            tokenomicName
        ];

        require(
            currentContract.contractAddress != address(0),
            "FXD: Address not exist"
        );
        require(
            currentContract.contractAddress.isContract(),
            "FXD: Address is not a contract"
        );
        require(
            currentContract.isAmountAllowed,
            "FXD: Amount exceed tokenomics"
        );

        currentContract.isAmountAllowed = false;
        SafeERC20.safeTransfer(
            IERC20(address(this)),
            currentContract.contractAddress,
            currentContract.amount
        );
        emit BusinessLogic(
            msg.sender,
            currentContract.contractAddress,
            tokenomicName,
            currentContract.amount
        );
        return true;
    }

    /**
       @param amount  Amount of token to be burned with treasury percentage
     */
    function burnWithTreasuryFee(uint256 amount) public returns (bool) {
        require(
            treasuryAddress != address(0),
            "FXD: Treasury address not exist"
        );
        uint256 percentageFeeToTreasure = treasuryFee * amount / 100;
        uint256 amountToBurn = amount - percentageFeeToTreasure;

        _burn(msg.sender, amountToBurn);

        SafeERC20.safeTransfer(
            IERC20(address(this)),
            treasuryAddress,
            percentageFeeToTreasure
        );
        return true;
    }

    /**
        @param fee     Amount of fee that are be deducted from burnWithTreasuryFee method
        @return bool
     */
    function setTreasuryFee(uint256 fee)
        public
        authorized()
        returns (bool)
    {
        require(fee <= 60, "FXD: Fee can't be more than 60%");
        treasuryFee = fee;
        return true;
    }

    /**
        @param _treasuryAddress Address of the contract tha are going to handle the Fees Treasury
        @return bool
     */
    function setTrasuryContract(address _treasuryAddress)
        public
        authorized()
        returns (bool)
    {
        require(_treasuryAddress.isContract(), "FXD: Is not a contract");
        treasuryAddress = _treasuryAddress;
        return true;
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
        require(_token != address(this), "FXD: You can't withdraw FXD");
        IERC20(_token).transfer(_receiver, _amount);
        return true;
    }

    /** REMAINDER BALANCES */
 
    /**
        @param _receiver Address of the wallet/contract to receive remainder tokens
        @param _amount Amount in wei to transfer, balance had to be available in the contract
     */
    function transferRemainderBalance(address _receiver, uint256 _amount)
        public
        authorized()
    {
        require(
            availableRemainderTokens() <= _amount,
            "FXD: Amount exceed remainder"
        );
        
        ERC20(address(this)).transfer(_receiver, _amount);
    }

    /**
        @return uint256 Returns actual remainder balance
     */
    function availableRemainderTokens() public view returns (uint256) {
        string[] memory _tokenomicNames = getAllowedTokenomicNames();
        uint256 remainder = 0;
        unchecked {
            for (uint8 i = 0; i < _tokenomicNames.length; i++) {
                remainder += allowedContract[_tokenomicNames[i]].isAmountAllowed
                    ? allowedContract[_tokenomicNames[i]].amount
                    : 0;
            }
        }

        uint256 totalRemainderCounter = ERC20(address(this))
            .balanceOf(address(this)) - remainder;
        return totalRemainderCounter == 0 ? 0 : totalRemainderCounter;
    }

    function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal override {
        require(Security.isSecured[msg.sender], "FXD: Cant purchase");        
        address addressToCooldown = _liquidityPairs[sender] ? recipient : sender;
        require(Antibot.isAvailableToTransact(addressToCooldown), "FXD: Wait your cooldown");

        if(_liquidityPairs[sender] == true || _liquidityPairs[recipient] == true) {
            uint256 taxCalculation = FoundationVAT.getFoundationVatFeeAmount(amount);
            amount -= taxCalculation; 
            super._transfer(sender, FoundationVAT.foundationVatAddress , taxCalculation);
        }
        
        if(Antibot.isAntibotEnabled) {
            Antibot.timeTransactionTracker[addressToCooldown] = block.timestamp;
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
