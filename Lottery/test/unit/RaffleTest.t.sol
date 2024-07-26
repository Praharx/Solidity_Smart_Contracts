// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test,console} from "forge-std/Test.sol";
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

     /*Events */
    event RaffleEnterPlayer(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external{
        DeployRaffle deployer = new DeployRaffle();
        (raffle,helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        //Why should I do this? -- to be used later in tests.
        entryFee = config.entryFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscribId = config.subscribId;
        callBackGasLimit = config.callBackGasLimit;

        vm.deal(PLAYER,STARTING_BALANCE);
    }

    function testRaffleStateinitialisesWithOpen() public view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN );
    }

    //////////// ENTER RAFFLE /////////////
    function testIfRaffleRevertsIfEntryFeeNotSufficient() public{
        //Arrange
        vm.prank(PLAYER);
        //Act/Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public{
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entryFee}();
        //Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitWhenPlayerEntersRaffle() public{
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true,false,false,false, address(raffle));
        emit RaffleEnterPlayer(PLAYER);
        //assert
        raffle.enterRaffle{value:entryFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public{
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        
        //Act/Assert
        vm.expectRevert(Raffle.Raffle__LotteryEntryClosed.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
    }
}