// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./Token/CharacterERC721Base.sol";

/// @custom:security-contact security@fursion.top
contract FurWorkToken is Initializable, CharacterERC721BaseUpgradeable, AccessManagedUpgradeable {
    uint256 private _nextTokenId;

    mapping(uint256 => address) internal _author;
    mapping(uint256 => string) internal _tokenURI;
    mapping(uint256 => bool) internal _confirmed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAuthority, address web3Entry) initializer public {
        __Context_init();
        __AccessManaged_init(initialAuthority);
        __CharacterERC721Base_init("FurWorkToken", "FWT", web3Entry);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return _tokenURI[id];
    }

    function authorOf(uint256 id) public view returns (address) {
        return _author[id];
    }

    function mint(uint256 characterId, string memory uri) public restricted {
        require(IERC721(_web3Entry).ownerOf(characterId) == msg.sender, "NOT_OWNER");

        uint256 tokenId = _nextTokenId++;
        _safeMint(characterId, tokenId);
        _setTokenURI(tokenId, uri);
        _author[tokenId] = msg.sender;
    }

    function adminMint(address artist, uint256 to, string memory uri) public restricted {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _author[tokenId] = artist;
        _confirmed[tokenId] = true;
    }

    function confirm(uint256 tokenId) public restricted {
        require(_ownerOf[tokenId] != 0, "NOT_MINTED");
        _confirmed[tokenId] = true;
    }

    function setAuthor(uint256 tokenId, address author) public restricted {
        require(_ownerOf[tokenId] != 0, "NOT_MINTED");
        require(_author[tokenId] != address(0), "CANNOT CHANGE AUTHOR");
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");

        _author[tokenId] = author;
    }

    function _transfer(
        uint256 from,
        uint256 to,
        uint256 id
    ) internal override {
        revert("NOT_ALLOW");
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURI[tokenId] = uri;
    }
}
