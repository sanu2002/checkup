// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

import {Script, console2} from "lib/forge-std/src/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/Networkconfig.s.sol";
import {Createsubscription} from "script/Interaction.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Fundsubscriotion} from "script/Interaction.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Addconsumer} from "script/Interaction.s.sol";

contract DeployRaffle is Script {
    event RaffleDeployed(address raffleAddress);

    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperconfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();

        // entranceFee: 0.01 ether,
        // interval: 30,
        // vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        // gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        // callbackGasLimit: 100000,
        // subscriptionId: 0,
        // linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
        // account: 0x307C9B74cb5D249b1653755B7384E2E1e565da15

        if (config.subscriptionId == 0) {
            Createsubscription createSubscription = new Createsubscription();
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator, config.account);

            Fundsubscriotion fundSubscription = new Fundsubscriotion();

            fundSubscription.fundSubscription(
                config.vrfCoordinator, config.subscriptionId, config.linkToken, config.account
            );

            helperconfig.setConfig(block.chainid, config);
        }

   

        vm.startBroadcast(config.account);

        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.callbackGasLimit,
            config.subscriptionId,
            config.linkToken,
            config.account
        );

        vm.stopBroadcast();
     
        Addconsumer addConsumer = new Addconsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);

        console2.log("Added Raffle contract as a consumer");
        emit RaffleDeployed(address(raffle));

        return (raffle, helperconfig);
    }
}
