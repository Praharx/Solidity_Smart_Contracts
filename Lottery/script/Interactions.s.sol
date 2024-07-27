// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig,CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mock/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConifg() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

        (uint256 subId,) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
        //create subscriptions
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on chain Id;", block.chainid);

        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id is", subId);
        console.log("Update your subscription Id in your HelperConfig.s.sol;");
        return (subId, vrfCoordinator);
    }

    function run() external {
        createSubscriptionUsingConifg();
    }
}

contract FundSubscription is Script,CodeConstants {
    uint256 FUND_AMOUNT = 3 ether; // 3 Link

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscribId = helperConfig.getConfig().subscribId;
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator,subscribId,linkToken);
    }

    function fundSubscription(address vrfCoordinator,uint256 subscribId,address linkToken) public {
        console.log("Funding Subscription:",subscribId);
        console.log("Using vrfCoordinator:",vrfCoordinator);
        console.log("On Chain Id",block.chainid);

        if(block.chainid == CodeConstants.LOCAL_CHAIN_ID ){
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscribId,FUND_AMOUNT);
            vm.stopBroadcast();
        } else{
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscribId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}
