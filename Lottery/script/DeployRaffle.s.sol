// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscribId == 0) {
            //create subscription.
            CreateSubscription subscriptionContract = new CreateSubscription();
            (config.subscribId, config.vrfCoordinator) = subscriptionContract.createSubscription(config.vrfCoordinator);

            //fund it
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entryFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscribId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}