//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DStableCoin} from "../src/DStableCoin.sol";
import {CSDEngine} from "../src/CSDEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployCSD is Script{
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DStableCoin,CSDEngine){
        HelperConfig config = new HelperConfig();
        (address wethUsdPriceFeed,address wbtcPriceFeed,address weth, address wbtc,uint deployerKey) = config.activeNetworkConfig();
        tokenAddresses = [weth,wbtc];
        priceFeedAddresses = [wethUsdPriceFeed,wbtcPriceFeed];
        vm.startBroadcast();
        DStableCoin dstableCoin = new DStableCoin();
        CSDEngine csd_engine = new CSDEngine(tokenAddresses,priceFeedAddresses,address(dstableCoin));

        dstableCoin.transferOwnership(address(csd_engine));
        vm.stopBroadcast();

        return (dstableCoin,csd_engine);
    }
}