//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {basicNft} from "../../src/basicNft.sol";
import {deployBasicNft} from "../../script/deployBasicNft.s.sol";

contract testBasicNft is Test {
    deployBasicNft public deployer;
    basicNft public BasicNft;
    address public USER = makeAddr("user");
    string public constant PUP = "ipfs://bafybeicuk6i5ok2ifguchqqfyiot5r4wjof3wkrv72w5dp65hvprtvdxka/";

    function setUp() public {
        deployer = new deployBasicNft();
        BasicNft = deployer.run();
    }

    function testIfTheNameIsCorrect() public view {
        string memory expectedName = "Puppy";
        string memory actualName = BasicNft.name();
        assert(keccak256(abi.encodePacked(expectedName)) == keccak256(abi.encodePacked(actualName)));
    }

    function testCanMintAndHaveABalance() public {
        vm.prank(USER);
        BasicNft.mintNft(PUP);

        assert(BasicNft.balanceOf(USER) == 1);
        assert(keccak256(abi.encodePacked(PUP)) == keccak256(abi.encodePacked(BasicNft.tokenURI(0))));
    }
}
