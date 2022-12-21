// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BlockHiveFractionToken is ERC20, ERC20Burnable {
    uint256 public NFTId;
    address public NFTOwner;
    address public NFTAddress;

    address public ContractDeployer;

    constructor(address _NFTAddress, uint256 _NFTId, address _NFTOwner, uint256 _supply, string memory _tokenName, string memory _tokenTicker) ERC20(_tokenName, _tokenTicker) {
        NFTAddress = _NFTAddress;
        NFTId = _NFTId;
        NFTOwner = _NFTOwner;
        
        ContractDeployer = msg.sender;
        
        _mint(_NFTOwner, _supply);
    }

    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    }

    function updateNFTOwner(address _newOwner) public {
        require(msg.sender == ContractDeployer, "Only contract deployer can call this function");
        NFTOwner = _newOwner;
    }
}
