// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample raffle contract
 * @author Praharx
 * @notice This contract aims to create a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    //Errors
    error Raffle__NotEnoughEthSent();
    error Raffle__WinnerTransactionFailed();
    error Raffle__LotteryEntryClosed();
    error Raffle__upkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 s_raffleState);

    /*Type declarations */
    enum RaffleState {
        OPEN, //0
        CALCULATING //1

    }

    /*State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint32 private immutable i_callBackGasLimit;
    uint256 private immutable i_entryFee;
    //@dev Interval of a lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /*Events */
    event RaffleEnterPlayer(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedWinnerId(uint256 indexed requestId);

    constructor(
        uint256 entryFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscribId,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entryFee = entryFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscribId;
        i_callBackGasLimit = callBackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entryFee,"Ooops!The amount sent is not equal to Entry Fee"); --- Strings are not gas - efficient. So method2:
        if (msg.value < i_entryFee) {
            revert Raffle__NotEnoughEthSent();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__LotteryEntryClosed();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnterPlayer(msg.sender);
    }

    //When should the winner be picked? And how to do it automatically?
    /**
     * @dev This function is called by the chainlink nodes to
     * see if its time to choose winner for lottery.
     * The following should be true in order for upKeepNeeded to be true:
     * 1. The defined interval should have passed between raffle runs
     * 2.The Lottery state is opened.
     * 3.The contract has ETH
     * 4. Implicitly, your subscription has LINK
     * @param -ignored
     * @return upkeepNeeded - true if its time to restart
     * @return - ignored
     */
    //would want to discuss this;
    function checkUpKeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "0x0");
    }

    //How to write a function? CIE -- Checks, Internal Contract state changes, External Interactions(Interacting with a different contract,etc.)
    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpKeep("");
        if (!upkeepNeeded) {
            revert Raffle__upkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState)); //Params are passed to give more info about revert
        }

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callBackGasLimit,
            numWords: NUM_WORDS,
            // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedWinnerId(requestId);
    }

    function fulfillRandomWords(uint256, /*requestId */ uint256[] memory randomWords) internal virtual override {
        //First comes checks

        //Internal state changes
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        //External Interactions
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__WinnerTransactionFailed();
        }
    }

    //Getter Functions
    function getEntryFee() external view returns (uint256) {
        return i_entryFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
