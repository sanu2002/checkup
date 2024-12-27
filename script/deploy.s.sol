// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/Networkconfig.s.sol";
import {Createsubscription} from "script/Interaction.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Fundsubscriotion} from "script/Interaction.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";



contract DeployRaffle is Script {
    event RaffleDeployed(address raffleAddress);

    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperconfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();

        if (config.subscriptionId == 0) {
            Createsubscription createSubscription = new Createsubscription();
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator);

            Fundsubscriotion fundSubscription = new Fundsubscriotion();
            fundSubscription.fundSubscription(
                config.vrfCoordinator, config.subscriptionId, config.linkToken
            );

        }

      

        vm.startBroadcast();

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





        emit RaffleDeployed(address(raffle));

        return (raffle, helperconfig); // This will return the deployed contract instance so that we will use in test env
    }
}
