// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


/// @custom:security-contact security@fursion.top
contract FursionToken is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, EIP712Upgradeable, ERC721VotesUpgradeable {
    uint256 private _nextTokenId;
    IERC721 public _parentToken;

    mapping(uint256 => uint256) private _tokenMapping;

    event MatchParent(uint256 indexed from, uint256 indexed to);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address parentToken) initializer public {
        __ERC721_init("FursionToken", "FTK");
        __ERC721Enumerable_init();
        __ERC721Pausable_init();
        __Ownable_init(initialOwner);
        __ERC721Burnable_init();
        __EIP712_init("FursionToken", "1");
        __ERC721Votes_init();
        setParentToken(parentToken);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 parentToken, string memory uri) public onlyOwner {
        require(_parentToken.ownerOf(parentToken), "you do not own the token");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenMapping[tokenId] = parentToken;

        emit MatchParent(tokenId, parentToken);
    }

    function getParentId(uint256 tokenId) {
        return _tokenMapping[tokenId];
    }

    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721Upgradeable, ERC721PausableUpgradeable, ERC721VotesUpgradeable)
    returns (address)
    {
        return super._update(to, tokenId, auth);
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