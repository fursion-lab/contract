// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @custom:security-contact security@fursion.top
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract CharacterERC721BaseUpgradeable is Initializable, IERC165 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(uint256 indexed from, uint256 indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    address public _web3Entry;

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => uint256) internal _ownerOf;

    mapping(uint256 => uint256) internal _balanceOf;

    function characterOwnerOf(uint256 id) public view virtual returns (uint256 owner) {
        require((owner = _ownerOf[id]) != 0, "NOT_MINTED");
    }

    function ownerOf(uint256 id) public view virtual returns (address) {
        uint256 characterId = characterOwnerOf(id);
        return IERC721(_web3Entry).ownerOf(characterId);
    }

    function characterBalanceOf(uint256 owner) public view virtual returns (uint256 ) {
        require(owner != 0, "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    function balanceOf(address owner) public view virtual returns (uint256 balance) {
        balance = 0;
        uint256 characterCount = IERC721(_web3Entry).balanceOf(owner);
        for (uint256 i = 0; i < characterCount; i++) {
            uint256 characterId = IERC721Enumerable(_web3Entry).tokenOfOwnerByIndex(owner, i);
            balance += _balanceOf[characterId];
        }
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function __CharacterERC721Base_init(string memory name_, string memory symbol_, address web3Entry_) internal onlyInitializing {
        __CharacterERC721Base_init_unchained(name_, symbol_, web3Entry_);
    }

    function __CharacterERC721Base_init_unchained(string memory name_, string memory symbol_, address web3Entry_) internal onlyInitializing {
        name = name_;
        symbol = symbol_;
        _web3Entry = web3Entry_;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external virtual {
        address owner = ownerOf(id);
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        uint256 from,
        uint256 to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != 0, "INVALID_RECIPIENT");

        require(
            msg.sender == ownerOf(from) || getApproved[id] == msg.sender || isApprovedForAll[ownerOf(from)][msg.sender],
            "NOT_AUTHORIZED"
        );

        _transfer(from, to, id);
        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        uint256 from,
        uint256 to,
        uint256 id
    ) external virtual {
        transferFrom(from, to, id);
    }

    function safeTransferFrom(
        uint256 from,
        uint256 to,
        uint256 id,
        bytes calldata data
    ) external virtual {
        transferFrom(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transfer(
        uint256 from,
        uint256 to,
        uint256 id
    ) internal virtual {
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function _mint(uint256 to, uint256 id) internal virtual {
        require(to != 0, "INVALID_RECIPIENT");

        require(_ownerOf[id] == 0, "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(0, to, id);
    }

    function _burn(uint256 id) internal virtual {
        uint256 owner = _ownerOf[id];

        require(owner != 0, "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, 0, id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(uint256 to, uint256 id) internal virtual {
        _mint(to, id);
    }

    function _safeMint(
        uint256 to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);
    }
}
