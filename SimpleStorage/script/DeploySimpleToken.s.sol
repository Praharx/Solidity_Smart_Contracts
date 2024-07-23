//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {SimpleToken} from "../src/SimpleToken.sol";

contract DeploySimpleToken is Script {
    function run() external returns (SimpleToken) {
        vm.startBroadcast();
        SimpleToken simpleToken = new SimpleToken(200);
        vm.stopBroadcast();
        return simpleToken;
    }
}
