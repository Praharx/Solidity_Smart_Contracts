//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract deployMoodNft is Script{
    function run() external returns (MoodNft){

    }

    function svgToImageUri(string memory svg) public pure returns (string memory){
        // converts svg --> base64
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgToBase64Encoded = Base64.encode(bytes(abi.encodePacked(svg)));
        return string(abi.encodePacked(baseURL,svgToBase64Encoded));

    }
    
}