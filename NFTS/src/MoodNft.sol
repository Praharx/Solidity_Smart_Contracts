//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    //errors
    error MoodNft__CantFlipCoinIfNotOwner();

    uint256 private s_tokenCounter;
    string private s_sadSvgImageUri;
    string private s_happySvgImageUri;

    constructor(string memory sadSvgImageUri, string memory happySvgImageUri) ERC721("Mood Nft", "UU") {
        s_tokenCounter = 0;
        s_sadSvgImageUri = sadSvgImageUri;
        s_happySvgImageUri = happySvgImageUri;
    }

    enum MOOD {
        HAPPY,
        SAD
    }

    mapping(uint256 => MOOD) private s_tokenIdToMood;

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = MOOD.HAPPY;
        s_tokenCounter++;
    }

    function flipMood(uint256 tokenId) public{
        //only want owner to be able to flip mode.
        if (!_isApprovedOrOwner(msg.sender,tokenId)){
            revert MoodNft__CantFlipCoinIfNotOwner();
        }

        if (s_tokenIdToMood[tokenId] == MOOD.HAPPY){
            s_tokenIdToMood[tokenId] = MOOD.SAD;
        } else{
            s_tokenIdToMood[tokenId] = MOOD.HAPPY;
        }
    } 

    function _isApprovedOrOwner(address requester, uint tokenId) internal view returns (bool){
        address owner = _ownerOf(tokenId);
        return (owner == requester || isApprovedForAll(owner,requester) || getApproved(tokenId) == requester);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory imageURI;
        if (s_tokenIdToMood[tokenId] == MOOD.HAPPY) {
            imageURI = s_happySvgImageUri;
        } else {
            imageURI = s_sadSvgImageUri;
        }

        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "',
                            name(),
                            '", "description": "An NFT that reflects the owners mode." ,"attributes": [{"trait_type": "modiness", "value" : 100}], "image": "',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function getMoodFromId(uint tokenId) public view returns (MOOD){
        return s_tokenIdToMood[tokenId];
    }
}
