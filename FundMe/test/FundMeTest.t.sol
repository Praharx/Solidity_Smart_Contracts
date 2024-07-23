// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;
    function setUp() external{
       DeployFundMe deployFundMe = new DeployFundMe();
       fundMe = deployFundMe.run();
    }

    function testMinimumDollarIsFive() view public{
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() view public{
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() view public{
        uint version = fundMe.getVersion();
        assertEq(version,4);
    }
}