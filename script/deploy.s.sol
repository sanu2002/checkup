// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

import {Script} from "lib/forge-std/src/Script.sol";
import {console} from "lib/forge-std/src/console.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/Networkconfig.s.sol";

contract DeployRaffle is Script {
    function run() external {
        // Deploy the HelperConfig to get the network configuration
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();


        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the Raffle contract
        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator
        );

        vm.stopBroadcast();

        // Log the deployed contract address
        console.log("Raffle deployed at:", address(raffle));
    }
}
