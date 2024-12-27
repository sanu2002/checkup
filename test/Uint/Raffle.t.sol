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
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

    function setUp() external {

           DeployRaffle deployRaffle = new DeployRaffle();  
           (raffle, helperConfig) = deployRaffle.run();
           vm.deal(PLAYER, STARTING_PLAYER_BALANCE);

           HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

            entranceFee=config.entranceFee;
            interval=config.interval;
            vrfCoordinator=config.vrfCoordinator;
            gasLane=config.gasLane;
            callbackGasLimit=config.callbackGasLimit;
            subscriptionId=config.subscriptionId ;
            link=LinkToken(config.linkToken);


            
            vm.startPrank(msg.sender);
            if (block.chainid == LOCAL_CHAIN_ID) {
                VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, LINK_BALANCE);
            }
            vm.stopPrank();
      

        
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


     

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee }();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act / Assert
        vm.expectRevert(Raffle.RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }







}
