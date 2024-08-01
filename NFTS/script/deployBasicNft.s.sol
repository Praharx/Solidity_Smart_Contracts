//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {basicNft} from "../src/basicNft.sol";

contract deployBasicNft is Script {
    function run() external returns (basicNft) {
        vm.startBroadcast();
        basicNft deployContract = new basicNft();
        vm.stopBroadcast();
        return deployContract;
    }
}
