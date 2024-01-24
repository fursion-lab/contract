// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @custom:security-contact security@fursion.top
contract FursionGovernor is Initializable, GovernorUpgradeable, GovernorSettingsUpgradeable, GovernorCountingSimpleUpgradeable, GovernorVotesUpgradeable, GovernorVotesQuorumFractionUpgradeable, GovernorTimelockControlUpgradeable {
    address private tokenAddress;
    mapping(uint256 => bool) private _proposalJoined;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IVotes _token, TimelockControllerUpgradeable _timelock, address _tokenAddress)
    initializer public
    {
        __Governor_init("FursionGovernor");
        __GovernorSettings_init(1, 5, 0);
//        __GovernorSettings_init(86400 /* 1 day */, 604800 /* 1 week */, 0);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(4);
        __GovernorTimelockControl_init(_timelock);
        tokenAddress = _tokenAddress;
    }

    function proposalJoin(uint256 parentToken, string memory description) external {
        require(msg.sender == IERC721(tokenAddress).ownerOf(parentToken), "only token owner can join");
        require(!_proposalJoined[parentToken], "already joined");
        _proposalJoined[parentToken] = true;

        address proposer = _msgSender();

        // check description restriction
        if (!_isValidDescriptionForProposer(proposer, description)) {
            revert GovernorRestrictedProposer(proposer);
        }

        address[] memory targets = new address[](1);
        targets[0] = address(this);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("grantToken(uint256,string)", parentToken, description);

        _propose(targets, values, calldatas, description, proposer);
    }

    // The following functions are overrides required by Solidity.

    function votingDelay()
    public
    view
    override(GovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
    public
    view
    override(GovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
    public
    view
    override(GovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
    returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
    public
    view
    override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(uint256 proposalId)
    public
    view
    override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    function proposalThreshold()
    public
    view
    override(GovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _queueOperations(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
    internal
    override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    returns (uint48)
    {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _executeOperations(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
    internal
    override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
    internal
    override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
    internal
    view
    override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    returns (address)
    {
        return super._executor();
    }
}