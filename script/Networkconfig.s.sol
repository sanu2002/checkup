// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/Uint/Mock/Linktoken.sol";

abstract contract CodeConstants {
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111; // Sepolia chain ID
    uint256 public constant LOCAL_CHAIN_ID = 31337; // Anvil local chain ID
    address public FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig_InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address linkToken;
        address account;
    }


    NetworkConfig public localNetworkConfig; // Mock contract config for local deployment

    mapping(uint256 => NetworkConfig) public networkConfig; // Mapping for real network settings

    constructor() {
        //11155111=ETH_SEPOLIA_CHAIN_ID
        networkConfig[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        localNetworkConfig = getOrCreateAnvilConfig();
    }
    function setConfig(uint256 chainid,NetworkConfig memory config) public {
        networkConfig[chainid] = config;
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

 

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (networkConfig[chainId].vrfCoordinator != address(0)) {
            return networkConfig[chainId]; //it will get the sepolia  network  ETH_SEPOLIA_CHAIN_ID=11155111
        } else if (chainId == LOCAL_CHAIN_ID) {
            return localNetworkConfig;
        } else {
            revert HelperConfig_InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 100000,
            subscriptionId: 70411538941694489046497923202791118104432774385494220775947143935576874819742,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x307C9B74cb5D249b1653755B7384E2E1e565da15
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // If already set, return localNetworkConfig
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        LinkToken link = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorV2_5Mock.createSubscription();
        console.log("Created subscription with ID:", subscriptionId);

        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: subscriptionId,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            interval: 30, // 30 seconds
            entranceFee: 0.01 ether,
            callbackGasLimit: 100000, // 500,000 gas
            vrfCoordinator: address(vrfCoordinatorV2_5Mock),
            linkToken: address(link),
            account: FOUNDRY_DEFAULT_SENDER
        });
        vm.deal(localNetworkConfig.account, 100 ether);
        return localNetworkConfig;
    }

  
}
