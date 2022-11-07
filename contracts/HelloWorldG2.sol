// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract HelloWorldG2 {
    string private text;
    address public owner;
    address[] public whitelist;
    mapping(address => bool) public isWhitelistedAddress;
    address[] public regents;
    mapping(address => bool) public isRegent;
    uint256 public numberOfRegentConfirmationsRequired;
    struct Transaction {
        string message;
        bool executed;
        uint numberOfTxConfirmations;
    }
    mapping(uint => bool) public isConfirmedTx;
    Transaction[] public transactions;

    event Whitelisted(address indexed whiteListedAddress);
    event RegentAppointed(address indexed regentAddress);
    event SetNumberOfRegentConfirmationsRequired(uint256);
    event TextModified(string indexed modifiedText);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TransactionSubmitted(address indexed regent, uint256 indexed txIndex,string indexed message);
    event TransactionConfirmed(address indexed regent, uint256 indexed txIndex);
    event TransactionExecuted(address indexed regent, uint256 indexed txIndex);
    event ConfirmationRevoked(address indexed regent, uint256 indexed txIndex);
    event RegentshipRevoked(address indexed regent);
    event WhitelistingRevoked(address indexed addressToBeRevoked);
    event ReceivedEth(uint256 amount);

    modifier onlyOwner()
    {
        require (msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyRegent()
    {
        require(isRegent[msg.sender], "Caller is not a regent");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmedTx[_txIndex], "Transaction already confirmed");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    modifier nonZeroAddress(address _addressToWhitelist){
        _addressToWhitelist != address(0x0);
        _;
    }

    constructor() {
        text = "Hello World";
        owner = msg.sender;
        isWhitelistedAddress[owner] = true;
        whitelist.push(owner);
        isRegent[owner] = true;
        regents.push(owner);
        numberOfRegentConfirmationsRequired = 1;
    }

    function whitelistAddress(address _addressToWhitelist) public onlyRegent nonZeroAddress(_addressToWhitelist) {
        require(!isWhitelistedAddress[_addressToWhitelist], "Address is already whitelisted");
        isWhitelistedAddress[_addressToWhitelist] = true;
        whitelist.push(_addressToWhitelist);

        emit Whitelisted(_addressToWhitelist);
    }

    function isWhitelisted(address _inputAddress) public view nonZeroAddress(_inputAddress) returns(bool) {
        bool whitelistStatus = isWhitelistedAddress[_inputAddress];
        return whitelistStatus;
    }

    function appointRegent(address _regentAddress) public onlyOwner nonZeroAddress(_regentAddress) {
        require(isWhitelistedAddress[_regentAddress], "Address is not whitelisted");
        require(!isRegent[_regentAddress], "Address is already a regent");
        isRegent[_regentAddress] = true;
        regents.push(_regentAddress);

        emit RegentAppointed(_regentAddress);
    }

    function revokeWhitelisting(address _addressToBeRevoked) public onlyOwner nonZeroAddress(_addressToBeRevoked) {
        require(isWhitelistedAddress[_addressToBeRevoked], "Address is not whitelisted");
        isWhitelistedAddress[_addressToBeRevoked] = false;
        for (uint256 i; i<whitelist.length; i++) {
            if (whitelist[i] == _addressToBeRevoked) {
                whitelist[i] = whitelist[whitelist.length - 1];
                whitelist.pop();
            }
        }

        emit WhitelistingRevoked(_addressToBeRevoked);
    }

    function revokeRegentship(address _addressToBeRevoked) public onlyOwner nonZeroAddress(_addressToBeRevoked) {
        require(isRegent[_addressToBeRevoked], "Address is not a regent");
        isRegent[_addressToBeRevoked] = false;
        for (uint256 i; i<regents.length; i++) {
            if (regents[i] == _addressToBeRevoked) {
                regents[i] = regents[regents.length - 1];
                regents.pop();
            }
        }
        emit RegentshipRevoked(_addressToBeRevoked);
    }

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return whitelist;
    }

    function getRegents() public view returns (address[] memory) {
        return regents;
    }

    function setnumberOfRegentConfirmationsRequired(uint256 _numberOfRegentConfirmationsRequired) public onlyOwner {
        require(_numberOfRegentConfirmationsRequired <= regents.length, "Invalid number of regent confirmations. Appoint more regents");
        numberOfRegentConfirmationsRequired = _numberOfRegentConfirmationsRequired;

        emit SetNumberOfRegentConfirmationsRequired(numberOfRegentConfirmationsRequired);
    }

    function submitTransaction(string memory _message) public onlyRegent {
        uint txIndex = transactions.length;
        transactions.push(
            Transaction({
                message: _message,
                executed: false,
                numberOfTxConfirmations: 0
            })
        );

        emit TransactionSubmitted(msg.sender, txIndex, _message);
    }

    function confirmTransaction(uint _txIndex) 
        public 
        onlyRegent 
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numberOfTxConfirmations += 1;
        isConfirmedTx[_txIndex] = true;

        emit TransactionConfirmed(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyRegent
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numberOfTxConfirmations >= numberOfRegentConfirmationsRequired,
            "More regents need to confirm the transaction"
        );
        setText(transaction.message);
        transaction.executed = true;

        emit TransactionExecuted(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyRegent
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmedTx[_txIndex], "Transaction has not been confirmed yet");
        transaction.numberOfTxConfirmations -= 1;
        isConfirmedTx[_txIndex] = false;

        emit ConfirmationRevoked(msg.sender, _txIndex);
    }

    function helloWorld() public view returns (string memory) {
        return text;
    }

    function setText(string memory _newText) private {
        text = _newText;

        emit TextModified(_newText);
    }

    function transferOwnership(address _newOwner) public onlyOwner nonZeroAddress(_newOwner) {
        address oldOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            string memory message,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];
        return (
            transaction.message,
            transaction.executed,
            transaction.numberOfTxConfirmations
        );
    }

    function receiveEther() public payable {
        emit ReceivedEth(msg.value);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance>0, "No Ether to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        receiveEther();
    }

    fallback() external payable{
        receiveEther();
    }
}
