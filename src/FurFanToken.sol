// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./Token/CharacterERC1155Base.sol";

/// @custom:security-contact security@fursion.top
contract FurFan is Initializable, ContextUpgradeable, CharacterERC1155BaseUpgradeable, AccessManagedUpgradeable {
    error NotAllow();
    error CannotIssueMultipleTokens();

    /*//////////////////////////////////////////////////////////////
                              Storage
    //////////////////////////////////////////////////////////////*/

    uint256 private _nextTokenId;

    mapping(address => uint256) public _issueTokenId;
    mapping(uint256 => address) public _creator;
    mapping(uint256 tokenId => string) private _tokenURIs;

    /*//////////////////////////////////////////////////////////////
                              Constructor
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAuthority, address web3Entry) initializer public {
        __Context_init();
        __AccessManaged_init(initialAuthority);
        __CharacterERC1155Base_init(web3Entry);
    }

    /*//////////////////////////////////////////////////////////////
                              Features
    //////////////////////////////////////////////////////////////*/

    function createToken(string memory uri) public restricted {
        require(_issueTokenId[msg.sender] == 0, "Fan: Cannot issue multiple token");

        uint256 tokenId = _nextTokenId++;
        _issueTokenId[msg.sender] = tokenId;
        _creator[tokenId] = msg.sender;
        _setTokenURI(tokenId, uri);
    }

    function adminCreateToken(address issuer, string memory uri) public restricted {
        require(_issueTokenId[issuer] == 0, "Fan: Cannot issue multiple token");

        uint256 tokenId = _nextTokenId++;
        _issueTokenId[issuer] = tokenId;
        _creator[tokenId] = issuer;
        _setTokenURI(tokenId, uri);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public restricted {
        require(_creator[tokenId] == msg.sender, "ERC1155: caller is not owner nor approved");
        _setTokenURI(tokenId, uri);
    }

    function creatorMint(
        uint256 to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(_creator[id] == msg.sender, "ERC1155: caller is not owner nor approved");
        _mint(to, id, amount, data);
    }

    function transferCreator(address from, address to, uint256 tokenId) public {
        require(_creator[tokenId] == from, "ERC1155: caller is not owner nor approved");
        _creator[tokenId] = to;
    }

    function adminMint(
        uint256 to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public restricted {
        _mint(to, id, amount, data);
    }

    function adminBatchMint(
        uint256 to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public restricted {
        _batchMint(to, ids, amounts, data);
    }


    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual override returns (string memory) {
        return _tokenURIs[id];
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        _tokenURIs[tokenId] = uri;
    }
}