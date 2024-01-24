// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";

contract FurCoin is ERC20, ERC20Burnable, ERC20Pausable, AccessManaged {

    mapping(address => bool) public _blacklist;

    constructor(address initialAuthority)
    ERC20("FurCoin", "FC")
    AccessManaged(initialAuthority)
    {}

    function pause() public restricted {
        _pause();
    }

    function unpause() public restricted {
        _unpause();
    }

    function mint(address to, uint256 amount) public restricted {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public restricted {
        _burn(from, amount);
    }

    function blacklist(address account) public restricted {
        _blacklist[account] = true;
    }

    function unblacklist(address account) public restricted {
        _blacklist[account] = false;
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
    internal
    override(ERC20, ERC20Pausable)
    {
        if (_blacklist[from] || _blacklist[to]) {
            revert("FurCoin: Blacklisted address");
        }
        super._update(from, to, value);
    }
}