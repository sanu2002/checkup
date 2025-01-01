// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

import {Test} from "lib/forge-std/src/Test.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import {console} from "lib/forge-std/src/console.sol";
import {LinkToken} from "test/Uint/Mock/Linktoken.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DeployRaffle} from "script/deploy.s.sol";
import {CodeConstants} from "../../script/Networkconfig.s.sol";
import {Raffle} from "src/Raffle.sol";



import {HelperConfig} from "../../script/Networkconfig.s.sol";

import {Vm} from "lib/forge-std/src/Vm.sol";

contract TestRaffle is Test, Script, CodeConstants {
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;
    LinkToken link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 100 ether;
    uint256 public constant LINK_BALANCE = 10 ether;

    function setUp() external {

        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);


        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        link = LinkToken(config.linkToken);

        vm.startPrank(msg.sender);
        if (block.chainid == LOCAL_CHAIN_ID) {
            link.mint(msg.sender, LINK_BALANCE);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, LINK_BALANCE);
        }
        link.approve(vrfCoordinator, LINK_BALANCE);
        vm.stopPrank();



 






        // console.log("Which netwroke you are in ",block.chainid);
    }

    function test_Rafflestateisopen() external view {
        assertEq(uint8(raffle.getrafflestate()), uint8(Raffle.RaffleState.OPEN));
    }

    /**
     * we are going to add 2 more test in the raffle to check whather the user has sufficent monwy to enter the raffle
     */
    /**
     * we will check whether the user data is got recorded or not because without recording that players deatils we are making a bad system
     */
    function test_enterrafflesuccess() public {
        vm.deal(PLAYER, 10 ether);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 1 ether}();
    }

    function test_lessrAdfflefeestojoin() public {
        vm.deal(PLAYER, 10 ether);
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.InsufficientEntranceFee.selector);
        raffle.enterRaffle{value: 0.00001 ether}();
    }

    function test_Evenetenit() public {
        vm.deal(PLAYER, 10 ether);
        vm.prank(PLAYER);

        // Expect the RaffleEntered event to be emitted with PLAYER as the argument
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);

        // Call the enterRaffle function
        raffle.enterRaffle{value: entranceFee}();
    }

    /**
     * s_raffleState = RaffleState.IN_PROGRESS;  make sure it is preventing the user for entering into the raffle
     */

    /*//////////////////////////////////////////////////////////////
                           ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");//[[we have written a lot of code jsut for this performUpkeep because hete we need to 
        // add consumer , create subscription and fund subscription so we have written a lot of code for this function]]
        

        // Act / Assert
        vm.expectRevert(Raffle.RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }



    /*//////////////////////////////////////////////////////////////
                          Checkupkeeep 
    //////////////////////////////////////////////////////////////*/

    function testcheckupkeeepisReturnfalseifithasnobalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assertEq(upkeepNeeded, false);

    }   


    function testcheckupkeepisfalseifraffleisnotopen() public {
           vm.prank(PLAYER);
           raffle.enterRaffle{value: entranceFee}();
           vm.warp(block.timestamp + interval + 1);
           vm.roll(block.number + 1);

           raffle.performUpkeep("");

        //    act 

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assertEq(!upkeepNeeded, true);




    }
    
    
    /*//////////////////////////////////////////////////////////////
                    constructor_initialization 
    //////////////////////////////////////////////////////////////*/



    function testisconstructorinitiliseperfectly() public{
        assertEq(entranceFee,helperConfig.getConfig().entranceFee);
        assertEq(interval, helperConfig.getConfig().interval);
        assertEq(vrfCoordinator, helperConfig.getConfig().vrfCoordinator);
        assertEq(gasLane, helperConfig.getConfig().gasLane);
        assertEq(callbackGasLimit, helperConfig.getConfig().callbackGasLimit);
        assertEq(subscriptionId, helperConfig.getConfig().subscriptionId);
        assertEq(address(link), helperConfig.getConfig().linkToken);


    }




    

    /*//////////////////////////////////////////////////////////////
                          performUpkeep 
    //////////////////////////////////////////////////////////////*/


    function testperformUpkeepifcheckupkeepistrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // vm.warp(block.timestamp ); // No time has passed so it's failing the test 
        vm.warp(block.timestamp + interval + 1); //This will pass the test and it will make checkupkeep true and run the perform upkeep
        vm.roll(block.number + 1);

        // Act
        raffle.performUpkeep("");

    }


            // if (!upkeepNeeded) revert RaffleUpkeepNotNeeded(address(this).balance, s_players.length, s_raffleState);


    function testisraffleupkeeynotneeded() public {

        uint256 currentbalance=0;
        uint256 playerlength=0;
        Raffle.RaffleState rafflestate=raffle.getrafflestate();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentbalance=currentbalance + entranceFee ;
        playerlength=playerlength+1;


        //we will write the logic for upkeepnotneeded 
        /* you can follow this guide how to handle custom error with parameters with the help of abi.encodeWithSelector :- https://book.getfoundry.sh/cheatcodes/expect-expectRevert    
        */
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.RaffleUpkeepNotNeeded.selector,
                currentbalance,
                playerlength,
                rafflestate
            )
        );
        raffle.performUpkeep("");



    }



            modifier raffleEntredAndTimePassed() {
            vm.prank(PLAYER);
            raffle.enterRaffle{value: entranceFee}();
            vm.warp(block.timestamp + interval + 1);
            vm.roll(block.number + 1);
            _;
        }


        function test_PerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntredAndTimePassed {
            // Act
            vm.recordLogs();
            raffle.performUpkeep(""); // emits requestId
            Vm.Log[] memory entries = vm.getRecordedLogs();
            bytes32 requestId = entries[1].topics[1];

            // Assert
            Raffle.RaffleState raffleState = raffle.getrafflestate();
            // requestId = raffle.getLastRequestId();

            assert(uint256(requestId) > 0);
            assert(uint(raffleState) == 1); // 0 = open, 1 = calculating


        }




    /*//////////////////////////////////////////////////////////////
                    constructor_initialization 
    //////////////////////////////////////////////////////////////*/


    function testfulfillrandomwordsafterperformupkeep(uint256 RandomRequestId) public {
          
                vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
                VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(RandomRequestId, address(raffle)); //in script we no need to manually add the request id and consumer 



                // VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(2, address(raffle)); //in script we no need to manually add the request id and consumer 
                // VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(3, address(raffle)); //in script we no need to manually add the request id and consumer 
                // VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(4, address(raffle)); //in script we no need to manually add the request id and consumer 



    }


    


    /*//////////////////////////////////////////////////////////////
                    time for winner picking  
    //////////////////////////////////////////////////////////////*/

    // step:1 :- first we will check the fulfill random words and will generate fulfil random words
    // step:2 :- then we will check the winner picking function

function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public {
    // Arrange
    uint256 additionalEntrants = 3;
    uint256 playerCount = 10;

    // Simulate multiple players entering the raffle
    for (uint256 i = 0; i < playerCount; i++) {
        address player = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
        hoax(player, STARTING_PLAYER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();
    }


    uint256 prize = entranceFee * playerCount;
    vm.recordLogs();
    raffle.performUpkeep("");

    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];

    // Simulate Chainlink VRF fulfilling the randomness
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
        uint256(requestId),
        address(raffle)
    );

    // Assert
    address recentWinner = raffle.getRecentWinner();
    Raffle.RaffleState raffleState = raffle.getrafflestate();
    uint256 winnerBalance = recentWinner.balance;
    uint256 endingTimestamp = raffle.lasttimestamp();

    assert(uint256(raffleState) == 0);
    assert(winnerBalance == STARTING_PLAYER_BALANCE + prize); 
    assert(endingTimestamp > 0); 
      
}



}