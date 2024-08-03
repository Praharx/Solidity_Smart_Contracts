//SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
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
 * It is simlar to DAI if DAI had no governance,no fees, and was only backed by WETH and WBTC.
 *
 * Our system should be "overcollateralized". This means at no point, should the value of all collateral <= the $backed value of CSD.
 *
 * @notice This contract is the core of CSD system.It handles all the logic for minting and redeeming CSD, as well as depositing & eithdrawing collateral.
 * @notice This contract is loosely based on MakerDAO DSS(DAI) system.
 */
pragma solidity ^0.8.18;

import {DStableCoin} from "./DStableCoin.sol";
import {ReentrancyGuard} from "@openzepplin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzepplin/contracts/token/ERC20/IERC20.sol";

contract CSDEngine is ReentrancyGuard {
    ////////////////// Errors //////////////////
    error CSDEngine__AmountIsZero();
    error CSDEngine__PriceFeedArrayLengthAndTokenAddressArrayLengthMismatch();
    error CSDEngine__TokenNotAllowed();
    error CSDEngine__CollateralDepositFailed();

    ////////////////// State variables //////////////////
    mapping(address token => address priceFeed) private s_priceFeeds; // TokentoPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    DStableCoin private immutable i_csd;

     ////////////////// Events //////////////////
     event CollateralDeposited(address indexed sender, address indexed tokenAddress, uint indexed amount);

    ////////////////// Modifiers //////////////////
    modifier MoreThanZero(uint256 amount) {
        if (amount == 0) {
            revert CSDEngine__AmountIsZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert CSDEngine__TokenNotAllowed();
        }
        _;
    }

    ////////////////// Functions //////////////////

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address csdAddress) {
        //USD pricefeeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert CSDEngine__PriceFeedArrayLengthAndTokenAddressArrayLengthMismatch();
        }

        //For example Eth/ usd, btc/ usd
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_csd = DStableCoin(csdAddress);
    }

    ////////////////// External Functions //////////////////
    function depositCollateralAndMintCSD() external {}

    /**
     * @notice follows CEI
     * @param tokenCollateralAddress The address of token (WETH/WBTC) to be deposited as token.)
     * @param amountCollateral The amount of collateral to deposit.
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        MoreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this),amountCollateral);
        if (!success){
            revert CSDEngine__CollateralDepositFailed();
        }
    }

    function mintCsd() external {}

    function RedeemCollateralForCSD() external {}

    function redeemCollateral() external {}

    function burnCsd() external {}

    function liqudate() external {}

    function getHealthFactor() external {}
}
