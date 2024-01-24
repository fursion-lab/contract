// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";

contract FursionAccessManager is Initializable, AccessManagerUpgradeable, ERC1155Upgradeable, ERC1155BurnableUpgradeable {
    error NotAllowed();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __AccessManager_init(initialOwner);
        __ERC1155_init("");
        __ERC1155Burnable_init();
    }

    function setURI(string memory newuri) public onlyAuthorized {
        _setURI(newuri);
    }

    /// @inheritdoc AccessManagerUpgradeable
    function _grantRole(
        uint64 roleId,
        address account,
        uint32 grantDelay,
        uint32 executionDelay
    ) internal override returns (bool) {
        bool newMember = super._grantRole(roleId, account, grantDelay, executionDelay);
        if (newMember) {
            _mint(account, roleId, 1, "");
        }
        return newMember;
    }

    /// @inheritdoc AccessManagerUpgradeable
    function _revokeRole(uint64 roleId, address account) internal override returns (bool) {
        bool removedMember = super._revokeRole(roleId, account);
        if (removedMember) {
            _burn(account, roleId, 1);
        }
        return removedMember;
    }

    // disable feature
    /// @inheritdoc ERC1155Upgradeable
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public override {
        revert NotAllowed();
    }

    /// @inheritdoc ERC1155Upgradeable
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) public override {
        revert NotAllowed();
    }
}