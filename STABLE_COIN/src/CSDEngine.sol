//SPDX-License-Identifier: MIT
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

/**
 * @title CSDEngine
 * @author Praharx
 * 
 * This system is designed on essential and minimilastic approach, and have the tokens maintain a 1 token == $1 peg.
 * This stablecoin has the properties:
 * - Exogenuos Collateral
 * - Dollar pegged
 * - Algorithmically pegged
 * 
 * It is simlar to DAI if DAI had no governance,no fees, and was only backed by WETH nd WBTC.
 * 
 * Our system should be "overcollateralized". This means at no point, should the value of all collateral <= the $backed value of CSD.
 * 
 * @notice This contract is the core of CSD system.It handles all the logic for minting and redeeming CSD, as well as depositing & eithdrawing collateral.
 * @notice This contract is loosely based on MakerDAO DSS(DAI) system.
 */

contract DSCEngine{
    function depositCollateralAndMintCSD() external {}

    /**
     * 
     * @param tokenCollateralAddress The address of token (WETH/WBTC) to be deposited as token.)
     * @param amountCollateral The amount of collateral to deposit.
     */
    function depositCollateral(address tokenCollateralAddress, uint amountCollateral) external {}

    function mintDsc() external {}

    function RedeemCollateralForCSD() external {}

    function redeemCollateral() external {}

    function burnDsc() external {}

    function liqudate() external {}

    function getHealthFactor() external {}

}