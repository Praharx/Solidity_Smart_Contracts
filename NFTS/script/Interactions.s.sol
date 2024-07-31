//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {basicNft} from "../src/basicNft.sol";

contract MintBasicNft is Script{
    string public constant PUP = "ipfs://bafybeicuk6i5ok2ifguchqqfyiot5r4wjof3wkrv72w5dp65hvprtvdxka/";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("basicNft",block.chainid);
        mintNftOnContract(mostRecentlyDeployed);
    }

    function mintNftOnContract(address contractAddress) public{
        vm.startBroadcast();
        basicNft(contractAddress).mintNft(PUP);
        vm.stopBroadcast();
    }
}