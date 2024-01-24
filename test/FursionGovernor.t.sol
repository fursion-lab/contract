// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/Governance/FursionGovernor.sol";

contract TokenTest is Test {
    FursionGovernor fg;

    function setUp() public {
        fg = new FursionGovernor();
    }

    function testName() public {
        assertEq(fg.name(), "Token");
    }
}
