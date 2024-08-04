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
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CSDEngine is ReentrancyGuard {
    ////////////////// Errors //////////////////
    error CSDEngine__AmountIsZero();
    error CSDEngine__PriceFeedArrayLengthAndTokenAddressArrayLengthMismatch();
    error CSDEngine__TokenNotAllowed();
    error CSDEngine__CollateralDepositFailed();
    error CSDEngine__MintRequestFailed();
    error CSDEngine__HEALTHFACTORDANGER(uint256 userHealthFactor);

    ////////////////// State variables //////////////////
    mapping(address token => address priceFeed) private s_priceFeeds; // TokentoPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountCSDMinted) private s_CSDMinted;
    address[] private s_CollateralTokens;
    uint256 private constant ADDITIONAL_PRECISION = 1e10;
    uint256 private constant PRECISION_NORMALIZE = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    DStableCoin private immutable i_csd;

    ////////////////// Events //////////////////
    event CollateralDeposited(address indexed sender, address indexed tokenAddress, uint256 indexed amount);

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
            s_CollateralTokens.push(tokenAddresses[i]);
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
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert CSDEngine__CollateralDepositFailed();
        }
    }

    /**
     * follows CIE
     * @param amountCsdToMint The amount of Csd coins to mint.
     * @notice the requester must have more collateral than the minimum threshold.
     */
    function mintCsd(uint256 amountCsdToMint) external MoreThanZero(amountCsdToMint) nonReentrant {
        s_CSDMinted[msg.sender] += amountCsdToMint;
        // if they minted too much $100Eth but minted $150 CSD
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_csd.mint(msg.sender, amountCsdToMint);
        if (!minted) {
            revert CSDEngine__MintRequestFailed();
        }
    }

    function RedeemCollateralForCSD() external {}

    function redeemCollateral() external {}

    function burnCsd() external {}

    function liqudate() external {}

    function getHealthFactor() external {}

    //////////////////  Private & Internal View Functions //////////////////

    function _getAccountInfo(address user)
        private
        view
        returns (uint256 totalCsdMinted, uint256 totalCollateralValueInUsd)
    {
        totalCsdMinted = s_CSDMinted[user];
        totalCollateralValueInUsd = getAccountCollateralValue(user);
    }

    /**
     *
     * returns how close a user is to liquidation
     * If a user gets this below 1, they can be liquidated.
     */
    function _healthFactor(address user) private view returns (uint256) {
        // CSD Minted
        // total collateral value
        (uint256 totalCsdMinted, uint256 totalCollateralValueInUsd) = _getAccountInfo(user);
        uint256 CollateralAdjustedThresholdPrecision =
            (totalCollateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (CollateralAdjustedThresholdPrecision * PRECISION_NORMALIZE) / totalCsdMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert CSDEngine__HEALTHFACTORDANGER(userHealthFactor);
        }
    }

    //////////////////  Public & External Functions //////////////////
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop throug collateral tokens ---> get how much user has deposited ---> map that to usd
        for (uint256 i = 0; i < s_CollateralTokens.length; i++) {
            address token = s_CollateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();

        return ((uint256(price) * ADDITIONAL_PRECISION) * amount) / PRECISION_NORMALIZE;
    }
}
