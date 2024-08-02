//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

import {ERC20,ERC20Burnable} from "@openzepplin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzepplin/contracts/access/Ownable.sol";

/**
 * @title Decentralised Stable Coin
 * @author Praharx
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 * 
 * This contract is governed by CSDEngine.This as ERC20 implementation of the stablecoin system.
 */

contract DStableCoin is ERC20Burnable,Ownable {
    //errors
    error DStableCoin__RevertZeroAddressReceiver();
    error DStableCoin__AmountCantBeZero();
    error DStableCoin__CantBurnZero();
    error DStableCoin__BalanceInSufficeToBurnThisAmount();
    constructor() ERC20("DStableCoin","CSD"){}

    function burn(uint _amount) public override onlyOwner{
        uint balance = balanceOf(msg.sender);

        if (_amount <= 0){
            revert DStableCoin__CantBurnZero();
        }

        if (balance < _amount){
            revert DStableCoin__BalanceInSufficeToBurnThisAmount();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint _amount) external onlyOwner returns (bool){
        if(_to == address(0)){
            revert DStableCoin__RevertZeroAddressReceiver();
        }
        if(_amount <= 0){
            revert DStableCoin__AmountCantBeZero();
        }
        _mint(_to,_amount);
        return true;
    }
}