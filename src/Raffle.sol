// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

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
// internal & private view & pure functions
// external & public view & pure functions

import {VRFConsumerBaseV2Plus} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A simple Raffle contract
 * @author
 * @notice This contract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // Errors
    error Moreraffle_Money();
    error Raffletransaction_Failed();
    error Raffleupkeepnotneeded(uint256 balance, uint256 numPlayers, Raflestate state);

    // Type declarations
    enum Raflestate {
        OPEN, // 0
        Inprogress, // 1
        Closed // 2

    }

    // State variables
    uint256 private immutable i_entrance;
    uint256 private immutable s_subscriptionid;
    uint256 private immutable i_interval;
    bytes32 private immutable s_keyhash;
    uint32 private constant callbackGasLimit = 40000;
    uint16 private constant requestConfirmations = 3;
    uint32 private constant numWords = 1;

    uint256 private s_lasttimestamp;
    address private s_recentwinner;
    address payable[] private s_players;
    Raflestate private s_raflestate;

    // Events
    event RaffleEvent(address indexed player);
    event WinnerPicked(address indexed winner);

    // Constructor
    constructor(uint256 entranceFee, uint256 interval, address _vrfCoordinator)
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        i_entrance = entranceFee;
        i_interval = interval;
        s_lasttimestamp = block.timestamp;
        s_raflestate = Raflestate.OPEN;
    }

    // External functions

    /**
     * @notice Allows a user to enter the raffle by paying the entrance fee
     */
    function EnterRaffle() external payable {
        if (msg.value < i_entrance) {
            revert Moreraffle_Money();
        }

        if (s_raflestate != Raflestate.OPEN) {
            revert("Raffle is not open");
        }

        s_players.push(payable(msg.sender));
        emit RaffleEvent(msg.sender);
    }

    /**
     * @notice Checks if the upkeep conditions are met
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeHasPassed = (block.timestamp - s_lasttimestamp) > i_interval;
        bool raffleOpen = s_raflestate == Raflestate.OPEN;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = timeHasPassed && raffleOpen && hasPlayers;
        return (upkeepNeeded, "");
    }

    /**
     * @notice Performs the upkeep by requesting random words from Chainlink VRF
     */
    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffleupkeepnotneeded(address(this).balance, s_players.length, s_raflestate);
        }

        s_raflestate = Raflestate.Inprogress; // Set the state to Inprogress

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyhash,
                subId: s_subscriptionid,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
            })
        );
    }

    /**
     * @notice Fulfills the random words request and selects the winner
     */
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIndex];
        s_recentwinner = recentWinner;

        // Reset the state
        s_raflestate = Raflestate.OPEN;
        delete s_players;

        s_lasttimestamp = block.timestamp;

        emit WinnerPicked(recentWinner);

        // Transfer the prize
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffletransaction_Failed();
        }
    }

    // View and Pure Functions

    /**
     * @notice Returns the entrance fee
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entrance;
    }

    /**
     * @notice Returns the recent winner
     */
    function getRecentWinner() external view returns (address) {
        return s_recentwinner;
    }
}
