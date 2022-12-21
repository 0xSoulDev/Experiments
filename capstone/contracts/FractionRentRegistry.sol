// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './FractionToken.sol';

contract FractionRentRegistry is Ownable {

    using SafeERC20 for IERC20;

    IERC20 public tokenUsedForRentPayments;
    IERC20 public investmentToken;

    uint256 public totalSupply;
    uint256 public totalRent;

    address contractOwner;

    mapping(address => uint256) public tenantAddressIndexMapping;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public totalRentPaid;
    mapping(address => uint) public rentShare;

    struct Tenant {
        address tenant;
        uint256 propertyID;
        uint256 depositAmount;
        uint256 rentAmount;
    }

    Tenant[] public tenantArray; 

    event RentDeposited(address tenant, uint256 amount, uint256 timestamp);
    event RentShareWithdrawn(address investor, uint256 amount, uint256 timestamp);
    event InvestmentTokenStaked(address investor, uint256 amount, uint256 timestamp);
    event InvestmentTokenUnstaked(address investor, uint256 amount, uint256 timestamp);
    event Received(address, uint);
    event FBReceived(address, uint);

    modifier notNullAddress(address _inputAddress){
        require(_inputAddress != address(0x0), "Input Adress can't be Zero Address");
        _;
    }

    constructor(
        address _investmentToken,
        address _tokenUsedForRentPayments,
        uint256 _totalRent
    ) {
        require(_investmentToken != address(0x0), "Input Adress can't be Zero Address");
        require(_tokenUsedForRentPayments != address(0x0), "Input Adress can't be Zero Address");
        require(_totalRent > 0, "Total Rent can't be 0");

        contractOwner = msg.sender;
        investmentToken = IERC20(_investmentToken);
        tokenUsedForRentPayments = IERC20(_tokenUsedForRentPayments);
        totalSupply = investmentToken.totalSupply();
        totalRent = _totalRent;
    }

    function addTenant(
        address _tenant,
        uint256 _propertyID,
        uint256 _depositAmount,
        uint256 _rentAmount
    ) public onlyOwner {
        Tenant memory tenantObject;       
        tenantObject.tenant = _tenant;
        tenantObject.propertyID = _propertyID;
        tenantObject.depositAmount = _depositAmount;
        tenantObject.rentAmount = _rentAmount;
        tenantArray.push(tenantObject);
        tenantAddressIndexMapping[_tenant] = tenantArray.length - 1; 
    }

    function removeTenant(address _tenant) public onlyOwner {
        uint256 index = tenantAddressIndexMapping[_tenant];
        tenantArray[index] = tenantArray[tenantArray.length - 1];
        tenantArray.pop();
        tenantAddressIndexMapping[tenantArray[index].tenant] = index;
    }
	
	function depositRent(uint256 _rentAmount) public {
        tokenUsedForRentPayments.safeApprove(msg.sender, _rentAmount);
        tokenUsedForRentPayments.safeTransferFrom(msg.sender, address(this), _rentAmount);
        emit RentDeposited(msg.sender, _rentAmount, block.timestamp);
        totalRentPaid[msg.sender] += _rentAmount;
    }

    function stakeinvestmentTokens(uint256 _tokenStakeAmount) public {
        require(_tokenStakeAmount > 0, "Can't stake 0 tokens");
        require(investmentToken.balanceOf(msg.sender) >= _tokenStakeAmount, "User's token balance is less than specified staking amount");
        investmentToken.safeTransferFrom(msg.sender, address(this), _tokenStakeAmount);
        balanceOf[msg.sender] += _tokenStakeAmount;
        emit InvestmentTokenStaked(msg.sender, _tokenStakeAmount, block.timestamp);
    }

    function calculateRentShare(address _investor) public {
        uint256 investorTokenAmount = balanceOf[_investor];
        uint256 rentSharePercent = (investorTokenAmount/totalSupply)*100;
        rentShare[_investor] = rentSharePercent*totalRent;
    }

    function claimRentShare() public {
        calculateRentShare(msg.sender);
        require(rentShare[msg.sender] > 0, "User doesn't have any rent share");
        require(rentShare[msg.sender] <= tokenUsedForRentPayments.balanceOf(address(this)), "Insufficient Rent Balance in Contract");
        uint256 withdrawnRentAmount = rentShare[msg.sender];
        rentShare[msg.sender] = 0;
        tokenUsedForRentPayments.safeTransfer(msg.sender, withdrawnRentAmount);
        emit RentShareWithdrawn(msg.sender, withdrawnRentAmount, block.timestamp);
    }

    function withdrawinvestmentTokens(uint256 _tokenWithdrawalAmount) public {
        require(_tokenWithdrawalAmount > 0, "Can't withdraw 0 tokens");
        require(balanceOf[msg.sender] >= _tokenWithdrawalAmount, "User's staked token balance is less than specified withdrawal amount");
        balanceOf[msg.sender] -= _tokenWithdrawalAmount;
        investmentToken.safeTransfer(msg.sender, _tokenWithdrawalAmount);
        emit InvestmentTokenUnstaked(msg.sender, _tokenWithdrawalAmount, block.timestamp);
    }

    function setTokenUsedForRentPayments(address _tokenUsedForRentPayments) public onlyOwner notNullAddress(_tokenUsedForRentPayments) {
        tokenUsedForRentPayments = IERC20(_tokenUsedForRentPayments);
    }

    function getBalanceOfStakedinvestmentTokens() public view returns(uint256) {
        return investmentToken.balanceOf(address(this));
    }

    function getBalanceOfRentDeposited() public view returns(uint256) {
        return tokenUsedForRentPayments.balanceOf(address(this));
    } 

    function getETHBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw; contract balance empty");
        
        (bool sent, ) = contractOwner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }  

    fallback() external payable {
        emit FBReceived(msg.sender, msg.value);
    }
}
