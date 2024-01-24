// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Token/CharacterERC721Base.sol";

interface IFurWorkToken {
    function adminMint(address artist, uint256 to, string memory uri) external;
    function authorOf(uint256 id) external view returns (address);
    function confirm(uint256 tokenId) external;
}


/// @custom:security-contact security@fursion.top
contract FurCommissionToken is Initializable, CharacterERC721BaseUpgradeable, AccessManagedUpgradeable, ReentrancyGuardUpgradeable {
    uint256 private _nextTokenId;

    event CommissionCreated(address indexed artist, uint256 indexed tokenId, uint256 price, uint256 owner, string uri);

    enum CommissionStage {
        Created,
        Accepted,
        Rejected,
        InProgress,
        PaymentRequired,
        Completed
    }

    struct Commission {
        address artist;
        uint256 totalPrice;
        uint256 totalPayed;
        uint256 totalReceived;
        uint256 totalClaimed;
        string uri;
        uint256 startedAt;
        uint256 endedAt;
        uint256 completedAt;
        uint256 resultId;
        CommissionStage stage;
        bool isArtist;
    }

    mapping(uint256 => Commission) public _data;
    address private _tokenAddress;
    address private _workAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAuthority, address web3Entry, address token, address work) initializer public {
        __AccessManaged_init(initialAuthority);
        __ReentrancyGuard_init();
        __CharacterERC721Base_init("FurCommissionToken", "FCT", web3Entry);
        _tokenAddress = token;
        _workAddress = work;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return _data[id].uri;
    }


    /*//////////////////////////////////////////////////////////////
                         Creation/Update Functions
    //////////////////////////////////////////////////////////////*/

    function artistMint(uint256 price, uint256 owner, uint128 endAt, string memory uri) public restricted {
        _nextTokenId++;
        uint256 tokenId = _nextTokenId;
        _data[tokenId] = Commission({
            artist: msg.sender,
            totalPrice: price,
            totalPayed: 0,
            totalReceived: 0,
            totalClaimed: 0,
            uri: uri,
            startedAt: block.timestamp,
            endedAt: endAt,
            completedAt: 0,
            resultId: 0,
            stage: CommissionStage.Accepted,
            isArtist: true
        });
        _mint(owner, tokenId);
        emit CommissionCreated(msg.sender, tokenId, price, owner, uri);
    }

    function userMint(address artist, uint256 price, uint256 owner, uint128 endAt, string memory uri) public restricted {
        _nextTokenId++;
        uint256 tokenId = _nextTokenId;
        _data[tokenId] = Commission({
            artist: artist,
            totalPrice: price,
            totalPayed: 0,
            totalReceived: 0,
            totalClaimed: 0,
            uri: uri,
            startedAt: block.timestamp,
            endedAt: endAt,
            completedAt: 0,
            resultId: 0,
            stage: CommissionStage.Created,
            isArtist: false
        });
        _mint(owner, tokenId);

        emit CommissionCreated(artist, tokenId, price, owner, uri);
    }

    function updatePrice(uint256 tokenId, uint256 price) public restricted {
        Commission storage commission = _data[tokenId];
        require(commission.stage == CommissionStage.Created, "Commission: commission not created");
        require(commission.artist == msg.sender || _getOwnerId(tokenId) == msg.sender, "Commission: not operator");
        commission.totalPrice = price;
    }

    function updateUri(uint256 tokenId, string memory uri) public restricted {
        Commission storage commission = _data[tokenId];
        require(commission.stage == CommissionStage.Created, "Commission: commission can only update uri when created");
        require(commission.artist == msg.sender || _getOwnerId(tokenId) == msg.sender, "Commission: not operator");
        commission.uri = uri;
    }

    function updateArtist(uint256 tokenId, address artist) public restricted {
        Commission storage commission = _data[tokenId];
        require(commission.stage == CommissionStage.Created, "Commission: commission can only update uri when created");
        require(commission.artist == msg.sender || _getOwnerId(tokenId) == msg.sender, "Commission: not operator");
        commission.artist = artist;
    }

    function acceptCommission(uint256 tokenId) public {
        Commission storage commission = _data[tokenId];
        require(commission.stage == CommissionStage.Created, "Commission: commission not created");
        require(commission.artist == msg.sender, "Commission: not artist");
        commission.stage = CommissionStage.Accepted;
    }

    function rejectCommission(uint256 tokenId) public {
        Commission storage commission = _data[tokenId];
        require(commission.stage == CommissionStage.Created, "Commission: commission not created");
        require(commission.artist == msg.sender, "Commission: not artist");
        commission.stage = CommissionStage.Rejected;
        commission.endedAt = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                         During Commission Functions
    //////////////////////////////////////////////////////////////*/

    function payCommission(uint256 tokenId) public {
        Commission storage commission = _data[tokenId];
        require(commission.stage == CommissionStage.Accepted, "Commission: commission not accepted");
        bool transferResult = IERC20(_tokenAddress).transferFrom(msg.sender, address(this), commission.totalPrice);
        require(transferResult, "Commission: transfer failed");

        commission.totalPayed += commission.totalPrice;
        commission.stage = CommissionStage.InProgress;
    }


    /*//////////////////////////////////////////////////////////////
                         Complete Commission Functions
    //////////////////////////////////////////////////////////////*/

    function completeCommission(uint256 tokenId) public {
        Commission storage commission = _data[tokenId];
        require(commission.stage == CommissionStage.InProgress, "Commission: commission not in progress");
        require(_getOwnerId(tokenId) == msg.sender, "Commission: not artist");
        commission.stage = CommissionStage.Completed;
        commission.completedAt = block.timestamp;
        commission.totalReceived = commission.totalPrice;

        IFurWorkToken(_workAddress).adminMint(commission.artist, _ownerOf[tokenId], commission.uri);
    }

    function claimCommission(uint256 tokenId) public nonReentrant {
        Commission storage commission = _data[tokenId];
        require(commission.artist == msg.sender, "Commission: not artist");

        uint256 commissionAmount = commission.totalReceived - commission.totalClaimed;
        require(commissionAmount > 0, "Commission: no commission to claim");
        commission.totalClaimed += commissionAmount;
        bool transferResult = IERC20(_tokenAddress).transfer(msg.sender, commissionAmount);
        require(transferResult, "Commission: transfer failed");
    }

    /*//////////////////////////////////////////////////////////////
                              Utility Functions
    //////////////////////////////////////////////////////////////*/

    function _getOwnerId(uint256 tokenId) internal view returns (address) {
        uint256 characterId = _ownerOf[tokenId];
        return IERC721(_web3Entry).ownerOf(characterId);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
}