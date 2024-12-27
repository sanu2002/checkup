// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

import {HelperConfig} from "script/Networkconfig.s.sol";
import {Script, console} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/Networkconfig.s.sol";
import {LinkToken} from "test/Uint/Mock/Linktoken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract Createsubscription is Script {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111; // Sepolia chain ID
    uint256 public constant LOCAL_CHAIN_ID = 31337; // Anvil local chain ID

    function CreateSubscriptionconfig() public returns (uint256, address) {
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = helperconfig.getConfig().vrfCoordinator;
        (uint256 subid,) = createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on chain ID:", block.chainid);

        vm.startBroadcast();
        uint256 subid = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("your sub id ", subid);
        return (subid, vrfCoordinator);
    }

    function run() public {
        CreateSubscriptionconfig();
    }
}

contract Fundsubscriotion is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 Link token

    function FundsubscriotionLinkConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().linkToken;

        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();

            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        FundsubscriotionLinkConfig();
    }
}
