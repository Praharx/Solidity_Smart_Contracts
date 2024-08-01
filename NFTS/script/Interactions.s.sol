//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {basicNft} from "../src/basicNft.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {MoodNft} from "../src/MoodNft.sol";

contract MintBasicNft is Script {
    string public constant PUP = "ipfs://bafybeicuk6i5ok2ifguchqqfyiot5r4wjof3wkrv72w5dp65hvprtvdxka/";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("basicNft", block.chainid);
        mintNftOnContract(mostRecentlyDeployed);
    }

    function mintNftOnContract(address contractAddress) public {
        vm.startBroadcast();
        basicNft(contractAddress).mintNft(PUP);
        vm.stopBroadcast();
    }
}

contract MintMoodNft is Script{
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MoodNft",block.chainid);
        // console.log("::::::;::",mostRecentlyDeployed);
        mintMoodNftOnContract(mostRecentlyDeployed);
    }

    function mintMoodNftOnContract(address contractAddr) public{
        vm.startBroadcast();
        MoodNft(contractAddr).mintNft();
        vm.stopBroadcast();
    }
}

contract FlipMood is Script{
    function run() external{
         address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MoodNft",block.chainid);
        // console.log("::::::;::",mostRecentlyDeployed);
        flipMoodOnContract(mostRecentlyDeployed);
    }

    function flipMoodOnContract(address contractAddress) public{
        vm.startBroadcast();
        MoodNft(contractAddress).flipMood(0);
        vm.stopBroadcast();
    }
}
