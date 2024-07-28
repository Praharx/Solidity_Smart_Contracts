// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import "forge-std/console.sol";

contract RaffleTest is Test {
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

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        //Why should I do this? -- to be used later in tests.
        entryFee = config.entryFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscribId = config.subscribId;
        callBackGasLimit = config.callBackGasLimit;

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleStateinitialisesWithOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    //////////// ENTER RAFFLE /////////////

    function testIfRaffleRevertsIfEntryFeeNotSufficient() public {
        //Arrange
        vm.prank(PLAYER);
        //Act/Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entryFee}();
        //Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitWhenPlayerEntersRaffle() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnterPlayer(PLAYER);
        //assert
        raffle.enterRaffle{value: entryFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
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

    //////////// CHECK UPKEEP /////////////
    function testcheckIfUpkeepHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upKeepNeeded,) = raffle.checkUpKeep("");

        //assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseWhenRaffleIsntOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act
        (bool upKeepNeed,) = raffle.checkUpKeep("");

        //Assert
        assert(!upKeepNeed);
    }

    function testCheckUpKeepReturnsFalseWhenEnoughTimeHasPassed() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();

        //Act
        (bool upKeepNeed,) = raffle.checkUpKeep("");

        //assert
        assert(!upKeepNeed);
    }

    function testCheckUpKeepReturnsTrueIfAllParametersAreGood() public {
        //Arrange
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.enterRaffle{value: entryFee}();

        //Act
        (bool upKeepNeed,) = raffle.checkUpKeep("");

        //assert
        assert(upKeepNeed);
    }

    //////////// PERFORM UPKEEP /////////////

    function testPerformUpKeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act/assert
        raffle.performUpkeep("");
    }

    function testPerformUpKeepWhenCheckUpKeepIsFalse() public {
        //Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        currentBalance = currentBalance + entryFee;
        numPlayers = 1;

        //Act/Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__upkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitRequestId() public raffleEntered {
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        //Extra
        // console.logBytes32(requestId);
        // for (uint256 i = 0; i < entries.length; i++) {
        //     console.log("Entry", i, "topics:", entries[i].topics.length);
        //     for (uint256 j = 0; j < entries[i].topics.length; j++) {
        //         console.logBytes32(entries[i].topics[j]);
        //     }
        // }

        //assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

     //////////// FULFILL RANDOM WORDS /////////////
    
    function testfulFillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(uint256 randomRequestId) public raffleEntered {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId,address(raffle));
    }

    function testFulfillrandomwordsPicksAWinnerResetsAndSendsMoney() public raffleEntered{
        //Arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for(uint256 i =startingIndex; i <  startingIndex + additionalEntrants;i++){
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entryFee}();
        }
        uint256 startingTimeStamp = raffle.getTimeStamp();
        uint256 startingBalance = expectedWinner.balance;

        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId= entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId),address(raffle));

        //Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimestamp =  raffle.getTimeStamp();
        uint256 prize = entryFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState)==0);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimestamp > startingTimeStamp);
    }

}