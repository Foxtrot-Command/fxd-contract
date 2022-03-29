// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "contracts/utils/Whitelist.sol";

/**
    @title Automathic seed sale
    @author Michael Araque
    @notice A contract that manages a Seed Sale pool, purchase, claiming and vesting time
 */

contract FoxtrotSeedSale is Whitelist {
    using SafeMath for uint256;

    enum InvestorTrace {
        CLAIMED,
        LOCKED,
        TOTAL,
        BUSD_INVESTED
    }

    enum ContractDates {
        CLAIM_START,
        SALE_START,
        SALE_END,
        VESTING_PERIOD
    }
    mapping(address => bool) private firstClaim;
    mapping(address => mapping(InvestorTrace => uint256)) private accounting;
    mapping(ContractDates => uint256) private dates;

    event ClaimToken(address tokenAddress, uint256 tokenAmount);
    event Invest(address investor, uint256 busdAmount, uint256 tokenAmount);

    address public busdContract;
    address public tokenContract;
    address public companyVault;

    bool private isClaimEnabled = false;
    uint256 private tokensSoldCounter;
    uint256 public totalBusdInvested;

    uint256 private immutable TGE_PERCENT = 5;
    uint256 private immutable AFTER_TGE_BLOCK_TIME = 90 days;
    uint256 private immutable FOXTROT_PRICE = 12500000000000000 wei;
    uint256 private immutable MIN_BUSD_ACCEPTED = 5000 ether;
    uint256 private constant MAX_AMOUNT_TOKEN = 32250000 ether;

    constructor(address _companyVault, address _busdContract) {
        companyVault = _companyVault;
        busdContract = _busdContract;
        tokenContract = address(0);

        tokensSoldCounter = MAX_AMOUNT_TOKEN;

        dates[ContractDates.SALE_START] = 1641164400;
        dates[ContractDates.SALE_END] = 1672700400;
        dates[ContractDates.VESTING_PERIOD] = 600 days;
        dates[ContractDates.CLAIM_START] = 0;
    }

    /**
        @param _amount      Amount to be invested in wei
     */
    function invest(uint256 _amount) public onlyWhitelisted {
        require(
            IERC20(busdContract).balanceOf(msg.sender) >= _amount,
            "FXD: Insufficient BUSD"
        );
        require(
            IERC20(busdContract).allowance(msg.sender, address(this)) >=
                _amount,
            "FXD: First grant allowance"
        );
        require(
            block.timestamp >= dates[ContractDates.SALE_START],
            "FXD: Seed Sale not started"
        );
        require(
            block.timestamp <= dates[ContractDates.SALE_END],
            "FXD: Seed Sale ended"
        );
        require(
            accounting[msg.sender][InvestorTrace.BUSD_INVESTED] <=
                Whitelist.amount[msg.sender] &&
                _amount <= Whitelist.amount[msg.sender] &&
                accounting[msg.sender][InvestorTrace.BUSD_INVESTED].add(
                    _amount
                ) <=
                Whitelist.amount[msg.sender],
            "FXD: Seed purchase limit"
        );

        if (
            tokensSoldCounter >=
            getTokenAmount(MIN_BUSD_ACCEPTED, FOXTROT_PRICE)
        )
            require(
                _amount >= MIN_BUSD_ACCEPTED,
                "FXD: Minimum amount 5000 BUSD"
            );

        uint256 tokensAmount = getTokenAmount(_amount, FOXTROT_PRICE);
        require(
            tokensSoldCounter > 0 && tokensSoldCounter >= tokensAmount,
            "FXD: Seed complete"
        );

        handleInvestment(msg.sender, tokensAmount, _amount);
        SafeERC20.safeTransferFrom(
            IERC20(busdContract),
            msg.sender,
            companyVault,
            _amount
        );

        emit Invest(msg.sender, _amount, tokensAmount);
    }

    /**
        @notice This method is added to handle extremly rare cases where investor can't invest directly on Dapp
        @param _to              Investor address
        @param _amount          Amount to be invested in wei
     */
    function manualInvest(address _to, uint256 _amount) public onlyOwner {
        uint256 tokensAmount = getTokenAmount(_amount, FOXTROT_PRICE);
        handleInvestment(_to, tokensAmount, _amount);
        emit Invest(_to, _amount, tokensAmount);
    }

    /**
        @param _from            Investor address
        @param _tokensAmount    Amount to be invested in wei
     */
    function handleInvestment(
        address _from,
        uint256 _tokensAmount,
        uint256 _busdAmount
    ) internal {
        tokensSoldCounter = tokensSoldCounter.sub(_tokensAmount);
        totalBusdInvested = totalBusdInvested.add(_busdAmount);
        accounting[_from][InvestorTrace.BUSD_INVESTED] = accounting[_from][
            InvestorTrace.BUSD_INVESTED
        ].add(_busdAmount);
        accounting[_from][InvestorTrace.LOCKED] = accounting[_from][
            InvestorTrace.LOCKED
        ].add(_tokensAmount);
        accounting[_from][InvestorTrace.TOTAL] = accounting[_from][
            InvestorTrace.TOTAL
        ].add(_tokensAmount);
    }

    /**
        @notice ClaimToken     Emit event
    */
    function claim() external onlyWhitelisted {
        require(isClaimEnabled, "FXD: Claim status inactive");
        require(
            accounting[msg.sender][InvestorTrace.LOCKED] > 0,
            "FXD: Already claimed your tokens"
        );

        if (!isElegibleForFirstClaim(msg.sender))
            require(
                block.timestamp >= dates[ContractDates.CLAIM_START],
                "FXD: Can't claim, 90 days cliff"
            );

        uint256 claimableTokens = handleClaim(msg.sender);
        SafeERC20.safeTransfer(
            IERC20(tokenContract),
            msg.sender,
            claimableTokens
        );

        emit ClaimToken(tokenContract, claimableTokens);
    }

    /**
        @param _from        Address of the caller
        @return uint256
    */
    function handleClaim(address _from) internal returns (uint256) {
        uint256 claimableTokens = getClaimableAmountOfTokens(_from);

        if (isElegibleForFirstClaim(_from) && isClaimEnabled) {
            firstClaim[msg.sender] = true;
        }

        accounting[_from][InvestorTrace.CLAIMED] = accounting[_from][
            InvestorTrace.CLAIMED
        ].add(claimableTokens);
        accounting[_from][InvestorTrace.LOCKED] = accounting[_from][
            InvestorTrace.LOCKED
        ].sub(claimableTokens);
        return claimableTokens;
    }

    /**
        @param _from        Address of the investor
        @return uint256
     */
    function getClaimableAmountOfTokens(address _from)
        public
        view
        returns (uint256)
    {
        uint256 _TGEPercent = getTGEPercent(_from);

        if (
            isElegibleForFirstClaim(_from) &&
            isClaimEnabled &&
            dates[ContractDates.CLAIM_START] != 0
        ) {
            return _TGEPercent;
        } else if (
            block.timestamp < dates[ContractDates.CLAIM_START] ||
            dates[ContractDates.CLAIM_START] == 0
        ) {
            return 0;
        } else if (
            block.timestamp >=
            dates[ContractDates.CLAIM_START].add(
                dates[ContractDates.VESTING_PERIOD]
            )
        ) {
            return accounting[_from][InvestorTrace.LOCKED];
        } else {
            uint256 amount = (
                (accounting[_from][InvestorTrace.TOTAL].sub(_TGEPercent))
                    .mul(
                        (block.timestamp.sub(dates[ContractDates.CLAIM_START]))
                    )
                    .div(dates[ContractDates.VESTING_PERIOD])
            ).sub((totalClaimedOf(_from).sub(_TGEPercent)));
            return amount;
        }
    }

    /**
        @param _from        Address of the investor
    */
    function getTGEPercent(address _from)
        internal
        view
        virtual
        returns (uint256)
    {
        return accounting[_from][InvestorTrace.TOTAL].mul(TGE_PERCENT).div(100);
    }

    /**
        @notice             Enabled first claim and active cliff time of 3 months
     */
    function changeClaimStatus() external onlyOwner returns (bool) {
        require(!isClaimEnabled, "FXD: Claim already enabled");
        isClaimEnabled = true;
        dates[ContractDates.CLAIM_START] = block.timestamp.add(
            AFTER_TGE_BLOCK_TIME
        );
        return true;
    }

    /**
        @notice             This method returns the exact date when the tokens
                            start to vesting
     */
    function claimStartAt() public view returns (uint256) {
        return dates[ContractDates.CLAIM_START];
    }

    /**
        @param _investor    Address of the investor
    */
    function isElegibleForFirstClaim(address _investor)
        public
        view
        returns (bool)
    {
        return !firstClaim[_investor];
    }

    /**
        @param _from        Address of the wallet that previously invested
        @return uint256
     */
    function totalLockedOf(address _from) public view returns (uint256) {
        return accounting[_from][InvestorTrace.LOCKED];
    }

    /**
        @param _from        Address of the wallet that previously invested
        @return uint256
     */
    function totalClaimedOf(address _from) public view returns (uint256) {
        return accounting[_from][InvestorTrace.CLAIMED];
    }

    /**
        @param _from        Address of the wallet that previously invested
        @return uint256
     */
    function totalOf(address _from) public view returns (uint256) {
        return accounting[_from][InvestorTrace.TOTAL];
    }

    /**
        @param _from        Address of the wallet that previously invested
        @return uint256
     */
    function availableOf(address _from) public view returns (uint256) {
        return getClaimableAmountOfTokens(_from);
    }

    /**
        @param _from        Address of the wallet that previously invested
        @return uint256
     */
    function totalBusdInvestedOf(address _from) public view returns (uint256) {
        return accounting[_from][InvestorTrace.BUSD_INVESTED];
    }

    /**
        @param _from        Address of the investor
        @return total
        @return claimed
        @return locked
        @return available
     */
    function investorAccounting(address _from)
        external
        view
        returns (
            uint256 total,
            uint256 claimed,
            uint256 locked,
            uint256 available,
            uint256 busd
        )
    {
        total = totalOf(_from);
        claimed = totalClaimedOf(_from);
        locked = totalLockedOf(_from);
        available = getClaimableAmountOfTokens(_from);
        busd = totalBusdInvestedOf(_from);
    }

    /**
        @param _from        Address of the investor
        @return uint256
     */
    function historicalBalance(address _from) internal view returns (uint256) {
        return (
            accounting[_from][InvestorTrace.LOCKED].add(
                accounting[_from][InvestorTrace.CLAIMED]
            )
        );
    }

    /**
        @param _amount      Amount in wei
        @param _tokenPrice  Price of the token in wei
        @return uint256     Amount without decimals
    */
    function getTokenAmount(uint256 _amount, uint256 _tokenPrice)
        internal
        pure
        returns (uint256)
    {
        return _amount.div(_tokenPrice) * (10**18);
    }

    /**
        @notice     This method is a helper function that allows to set the end of the sale manually
     */
    function setSaleEnd() public onlyOwner returns (bool) {
        dates[ContractDates.SALE_END] = block.timestamp;
        return true;
    }

    /**
        @param _fxdToken Contract address of FXD Token
     */
    function setContractToken(address _fxdToken)
        public
        onlyOwner
        returns (bool)
    {
        tokenContract = _fxdToken;
        return true;
    }

    /**
        @param _token address
        @return uint256
     */
    function balance(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
        @notice This method allow the owner of the contract to transfer specific amount of non Foxtrot tokens to a specific address manually
        @param _token       Address of the token contract
        @param _receiver    Address of the wallet that will receive the tokens
        @param _amount      Amount of tokens to be transfered
     */
    function withdraw(
        address _token,
        address _receiver,
        uint256 _amount
    ) public onlyOwner returns (bool) {
        require(
            _token != tokenContract,
            "FXD: You can't withdraw Foxtrot Tokens"
        );
        IERC20(_token).transfer(_receiver, _amount);
        return true;
    }

    /**
        @notice Return all excess tokens in the Seed Sale Contract to the Foxtrot Command (FXD) Contract
     */
    function purgeNonSelledTokens() external onlyOwner {
        require(
            block.timestamp >= dates[ContractDates.SALE_END],
            "FXD: Seed sale is still alive"
        );
        SafeERC20.safeTransfer(
            IERC20(tokenContract),
            tokenContract,
            tokensSoldCounter
        );
    }
}
