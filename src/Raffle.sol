// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

// Imports
import {VRFConsumerBaseV2Plus} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Simple Raffle Contract
 * @notice This contract allows users to enter a raffle with automated winner selection using Chainlink VRF v2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // Errors
    error InsufficientEntranceFee();
    error TransactionFailed();
    error RaffleNotOpen();
    error RaffleUpkeepNotNeeded(uint256 balance, uint256 numPlayers, RaffleState state);

    // Enum: Raffle State
    enum RaffleState {
        OPEN, // 0
        IN_PROGRESS, // 1
        CLOSED // 2

    }

    // State Variables
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;

    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    address payable[] private s_players;
    RaffleState private s_raffleState;

    // VRF Parameters
    uint32 private constant CALLBACK_GAS_LIMIT = 40000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    // Constructor
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint32 callbackGasLimit,
        uint256 subscriptionId,
        address linkToken,
        address account

    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_keyHash = gasLane;

        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    /**
     * @notice Allows a user to enter the raffle
     */
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert InsufficientEntranceFee();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @notice Check if upkeep is needed
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timePassed = (block.timestamp - s_lastTimestamp) > i_interval;
        bool hasPlayers = s_players.length > 0;
        bool raffleOpen = s_raffleState == RaffleState.OPEN;

        upkeepNeeded = timePassed && hasPlayers && raffleOpen;
        return (upkeepNeeded, "0x0");
    }

    /**
     * @notice Performs upkeep and requests random words
     */
    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) revert RaffleUpkeepNotNeeded(address(this).balance, s_players.length, s_raffleState);

        s_raffleState = RaffleState.IN_PROGRESS;

        // Request random words
        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
            })
        );
    }

    /**
     * @notice Fulfills random words and picks the winner
     */
    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;

        // Reset the raffle
        s_raffleState = RaffleState.OPEN;
        delete s_players;
        s_lastTimestamp = block.timestamp;

        emit WinnerPicked(winner);

        // Transfer winnings
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) revert TransactionFailed();
    }

    // View Functions
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getrafflestate() external view returns (RaffleState) {
        return s_raffleState;
    }
}
