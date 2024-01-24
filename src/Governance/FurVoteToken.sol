// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @custom:security-contact security@fursion.top
contract FurVote is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721PausableUpgradeable, AccessManagedUpgradeable, ERC721BurnableUpgradeable, EIP712Upgradeable, ERC721VotesUpgradeable {
    uint256 private _nextTokenId;
    IERC721 public _parentToken;

    // Token ID => Parent Token ID
    mapping(uint256 => uint256) private _tokenMapping;
    // Parent Token ID => Token ID
    mapping(uint256 => uint256) private _parentMapping;
    mapping(uint256 => string) private _granted;
    mapping(uint256 => bool) private _revoked;

    event MatchParent(uint256 indexed from, uint256 indexed to);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAuthority, address parentToken) initializer public {
        __ERC721_init("FurVote", "FVT");
        __ERC721URIStorage_init();
        __ERC721Pausable_init();
        __AccessManaged_init(initialAuthority);
        __ERC721Burnable_init();
        __EIP712_init("FurVote", "1");
        __ERC721Votes_init();
        setParentToken(parentToken);
    }

    function pause() public restricted {
        _pause();
    }

    function unpause() public restricted {
        _unpause();
    }

    function safeMint(address to, uint256 parentToken, string memory uri) public restricted {
        require(_parentToken.ownerOf(parentToken) == to, "must send to token owner");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenMapping[tokenId] = parentToken;
        _parentMapping[parentToken] = tokenId;

        emit MatchParent(tokenId, parentToken);
    }

    function grantToken(uint256 parentToken, string memory uri) public restricted {
        require(_parentMapping[parentToken] == 0, "must not minted");
        require(bytes(_granted[parentToken]).length == 0, "must not granted");
        require(_revoked[parentToken] == false, "must not revoked");
        _granted[parentToken] = uri;
    }

    function claim(uint256 parentToken) public {
        require(_parentToken.ownerOf(parentToken) == msg.sender, "must send to token owner");
        require(bytes(_granted[parentToken]).length != 0, "must granted first");
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _granted[parentToken]);
        delete _granted[parentToken];
        _tokenMapping[tokenId] = parentToken;
        _parentMapping[parentToken] = tokenId;

        emit MatchParent(tokenId, parentToken);
    }

    function revoke(uint256 parentToken) public restricted {
        require(_parentMapping[parentToken] != 0, "must minted");
        require(_revoked[parentToken] == false, "must not revoked");
        delete _granted[parentToken];
        _revoked[parentToken] = true;
        uint256 tokenId = _parentMapping[parentToken];
        _burn(tokenId);
        delete _tokenMapping[tokenId];
        delete _parentMapping[parentToken];
    }

    function setParentToken(address parentToken) public restricted {
        _parentToken = IERC721(parentToken);
    }

    function getParentId(uint256 tokenId) public view returns(uint256) {
        return _tokenMapping[tokenId];
    }

    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721Upgradeable, ERC721PausableUpgradeable, ERC721VotesUpgradeable)
    returns (address)
    {
        address previousOwner = super._update(to, tokenId, auth);
//        _delegate(to, to);
        return previousOwner;
    }

    function _increaseBalance(address account, uint128 value)
    internal
    override(ERC721Upgradeable, ERC721VotesUpgradeable)
    {
        super._increaseBalance(account, value);
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
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}