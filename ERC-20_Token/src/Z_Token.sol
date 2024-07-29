//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzepplin/contracts/token/ERC20/ERC20.sol";

contract Z_Token is ERC20{
    constructor(uint256 initialSupply) ERC20("Z_Token", "PT"){
        _mint(msg.sender,initialSupply);
    }
}