// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external{
       DeployFundMe deployFundMe = new DeployFundMe();
       fundMe = deployFundMe.run();
       vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() view public{
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() view public{
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() view public{
        uint version = fundMe.getVersion();
        assertEq(version,4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //hey you better revert the next line orelse the test fails
        fundMe.fund(); //send 0 value
    }

    function testFundUpdatesFundedDataStructures() public {
        vm.prank(USER); //the next transactions shall be made by this address.
        fundMe.fund{value:VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded,VALUE);
    }

    function testAddsFunderToArrayOfFunders() public{
        vm.prank(USER);
        fundMe.fund{value:VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder,USER);
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value:VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public{
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunderCheaper() public{
        //Arrange
        uint256 startingBalance = fundMe.getOwner().balance;
        uint256 fundMeBalance = address(fundMe).balance;

        //Act
        
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithDraw();//200
       
        //assert
        uint256 endingBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingBalance+fundMeBalance,endingBalance);
    }

    function testwithdrawWithMultipleFunderCheaper() public {
        //Arrange
        uint160 numberOfFunders = 10;//the reason to use uint160 its the exact size an address would need when we initiate like address(1),address(2)etc.
        uint160 startingIndex = 1;

        for(uint160 i = startingIndex;i <= numberOfFunders;i++){
            hoax(address(i),VALUE);
            fundMe.fund{value:VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithDraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance+startingFundMeBalance == fundMe.getOwner().balance);
    }
}