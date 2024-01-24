// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

contract FursionTimeLock is Initializable, TimelockControllerUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin) initializer public {
    __TimelockController_init(minDelay, proposers, executors, admin);
  }
}