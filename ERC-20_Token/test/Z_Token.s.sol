//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployToken} from "../script/DeployZ_Token.s.sol";
import {Z_Token} from "../src/Z_Token.sol";

contract TestToken is Test{
    Z_Token public z_token;
    DeployToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public{
        deployer = new DeployToken();
        z_token = deployer.run();

        vm.prank(msg.sender);
        z_token.transfer(bob,STARTING_BALANCE);
    }

    function testbobBalance() public{
        assertEq(STARTING_BALANCE,z_token.balanceOf(bob));
    }

    function testAllowancesWork() public{
        uint initalAllowances = 1000;
    
        //Bob approves alice to spend tokens on her behalf
        vm.prank(bob);
        z_token.approve(alice,initalAllowances);

        uint transferAmount = 500;

        vm.prank(alice);
        z_token.transferFrom(bob,alice,transferAmount);

        assertEq(z_token.balanceOf(alice),transferAmount);
        assertEq(z_token.balanceOf(bob),STARTING_BALANCE - transferAmount);
    }
}