// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

import {HelperConfig} from "script/Networkconfig.s.sol";
import {Script, console} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/Networkconfig.s.sol";
import {LinkToken} from "test/Uint/Mock/Linktoken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "src/Raffle.sol";

import {DeployRaffle} from "script/deploy.s.sol";

contract Createsubscription is Script {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111; // Sepolia chain ID
    uint256 public constant LOCAL_CHAIN_ID = 31337; // Anvil local chain ID

    function CreateSubscriptionconfig() public returns (uint256, address) {
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = helperconfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperconfig.getConfigByChainId(block.chainid).subscriptionId;
        address account = helperconfig.getConfigByChainId(block.chainid).account;
        return createSubscription(vrfCoordinator, account);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        vm.startBroadcast(account);
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subscriptionId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (subscriptionId, vrfCoordinator);
    }

    function run() external returns(uint256, address) {
        CreateSubscriptionconfig();
    }
}



// contract YourContract {

//     // Check if the address is a contract
//     function isContract(address _addr) internal view returns (bool) {
//         uint256 size;
//         // Assembly to get the code size of the address
//         assembly {
//             size := extcodesize(_addr)
//         }
//         return size > 0;
//     }
// }

contract Fundsubscriotion is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 Link token


    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinator;
        address link = helperConfig.getConfig().linkToken;
        address account = helperConfig.getConfig().account;

        if (subId == 0) {
            Createsubscription createSub = new Createsubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinatorV2_5 = updatedVRFv2;
            console.log("New SubId Created! ", subId, "VRF Address: ", vrfCoordinatorV2_5);
        }

        fundSubscription(vrfCoordinatorV2_5, subId, link, account);
    }

    function fundSubscription(address vrfCoordinatorV2_5, uint256 subId, address link, address account) public {

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            bool success =LinkToken(link).transferAndCall(vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(subId));
            require(success, "Funding subscription failed");

            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

// add consumer by fetching the recent deplpoyed address
//you can use foundry devopps for fetching latest deplyed address

contract Addconsumer is Script {

    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, address account) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinatorV2_5, subId, account);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }

}
