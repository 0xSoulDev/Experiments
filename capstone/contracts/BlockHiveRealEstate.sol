//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract BlockHiveRealEstate is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    // contract level property attributes 
    mapping(uint256 => _propertyData) private _propertyAttributes;

    // for enhanced token URI mapping / metadata freezing
    struct _propertyData {
        string _paperworkURI;
        string _attributesURI;
        string _propertyAddress;
        string _propertyID;
        address _propertyManager;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("BlockHiveRealEstate", "BHRE");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function safeMint(address to, string memory uri, _propertyData calldata propertyAttributes) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _propertyAttributes[tokenId] = propertyAttributes;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /**
     * @dev set property attributes
     */
    function updatePropertyAttributes(uint256 tokenId, string calldata attributesURI) public     
    {
        _propertyData memory currentPropertyData;
        currentPropertyData = getPropertyAttributes(tokenId);
        require(_exists(tokenId), "You tried to set the attributes for a non-existent tokenID");
        require(msg.sender == currentPropertyData._propertyManager, "Only the property manager can set property Metadata");
        _propertyAttributes[tokenId]._attributesURI = attributesURI;
    }

    function getPropertyAttributes(uint256 tokenId) 
        public 
        view 
        returns (_propertyData memory propertyData)     
    {
        propertyData = _propertyAttributes[tokenId];
        return propertyData;
    }

    /**
     * @dev override the standard set token function to incorporate metadata updates by the property manager
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) onlyOwner
        public
    {
        super._setTokenURI(tokenId, _tokenURI);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
