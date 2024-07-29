//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Z_Token} from "../src/Z_Token.sol";

contract DeployToken is Script{
    uint256 INITAL_SUPPLY = 10000 ether;
    function run() external returns (Z_Token){
     vm.startBroadcast();
     Z_Token z_token = new Z_Token(INITAL_SUPPLY);
     vm.stopBroadcast();
     return z_token;
    }
}