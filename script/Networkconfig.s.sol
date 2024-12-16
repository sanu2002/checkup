// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

import {Script} from "lib/forge-std/src/Script.sol";
import {CodeConstants} from "script/abstarct.s.sol";
import {MockVRFCoordinator} from "script/Mockcontract.s.sol";



contract HelperConfig is Script,CodeConstants{
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
    }

    NetworkConfig public  activeNetworkConfig;

    constructor() {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            activeNetworkConfig = getLocalConfig();
        } else {
            revert("Unsupported network");
        }
    }


	

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000, // 500,000 gas
            subscriptionId: 0 // Replace with your subscription ID
        });
    }

    function getLocalConfig() public returns (NetworkConfig memory) {
        MockVRFCoordinator mockVrfCoordinator = new MockVRFCoordinator();

        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, 
            vrfCoordinator: address(mockVrfCoordinator),
            gasLane: "",
            callbackGasLimit: 500000,
            subscriptionId: 0 // No subscription ID for local
        });
    }

	function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
			return activeNetworkConfig;
	}


  



}
