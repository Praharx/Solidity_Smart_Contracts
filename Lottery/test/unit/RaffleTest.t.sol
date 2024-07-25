// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
 
contract RaffleTest is Test{
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    uint256 entryFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscribId;
    uint32 callBackGasLimit;

    function setUp() external{
        DeployRaffle deployer = new DeployRaffle();
        (raffle,helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        //Why should I do this? 
        entryFee = config.entryFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscribId = config.subscribId;
        callBackGasLimit = config.callBackGasLimit;
    }

    function testRaffleStateinitialisesWithOpen() public view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN );
    }

    //////////// ENTER RAFFLE /////////////
    function testRaffleRevertsIfEntryFeeNotSufficient() public{
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectRevert()
        //Assert
    }

}