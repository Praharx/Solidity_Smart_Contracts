// I'm gonna come back to this before I start my ethereum journey again for security audits!!!

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {DeployCSD} from "../../script/DeployCSD.s.sol";
import {DStableCoin} from "../../src/DStableCoin.sol";
import {CSDEngine} from "../../src/CSDEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzepplin/contracts/mocks/ERC20Mock.sol";

contract testCSD is Test {
    DeployCSD deployer;
    DStableCoin dStableCoin;
    CSDEngine csd_engine;
    HelperConfig config;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployCSD();
        (dStableCoin, csd_engine, config) = deployer.run();
        (wethUsdPriceFeed,wbtcUsdPriceFeed, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    ///////////////////// CONSTRUCTOR TESTS /////////////////////
    address[] tokenAddresses;
    address[] priceFeedAddresses;

    function testRevertsIfTokenAddressesLengthIsNotEqualToPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(wethUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);

        vm.expectRevert(CSDEngine.CSDEngine__PriceFeedArrayLengthAndTokenAddressArrayLengthMismatch.selector);
        new CSDEngine(tokenAddresses,priceFeedAddresses,address(dStableCoin));

    }

    ///////////////////// PRICE TESTS /////////////////////

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        // 15e18 * 2000/eth = 30000e18
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = csd_engine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }


    function testGetTokenAmountFromUsd() public view{
        uint usdAmount = 100 ether;
        // $2000/ ETH ==> 100/2000 = 0.05 ETh
        uint expectedAmountInWei = 0.05 ether;
        uint actualWei = csd_engine.getTokenAmountFromUsd(weth, usdAmount);

        assertEq(actualWei,expectedAmountInWei);
    }

    ///////////////////// DEPOSIT COLLATERAL TESTS /////////////////////

    function testRevertsWhenAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(csd_engine), AMOUNT_COLLATERAL);

        vm.expectRevert(CSDEngine.CSDEngine__AmountIsZero.selector);
        csd_engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsIfNotAllowedCollateralIsGiven() public {
        ERC20Mock DUCKS = new ERC20Mock("DUCK","DUCK",USER,AMOUNT_COLLATERAL);
        vm.startPrank(USER);

        vm.expectRevert(CSDEngine. CSDEngine__TokenNotAllowed.selector);
        csd_engine.depositCollateral(address(DUCKS),AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(csd_engine),AMOUNT_COLLATERAL);
        csd_engine.depositCollateral(weth,AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndRetrieveAccountInfo() public depositedCollateral{
        (uint totalCsdMinted,uint totalCollateralValueInUsd) = csd_engine.getAccountInfo(USER);

        uint expectedtotalCSDMinted = 0;
        uint expectedCollateralValueInUsd = csd_engine.getTokenAmountFromUsd(weth,totalCollateralValueInUsd);
        assertEq(totalCsdMinted,expectedtotalCSDMinted);
        console.log(expectedCollateralValueInUsd,"::::::",totalCollateralValueInUsd);
        assertEq(expectedCollateralValueInUsd,AMOUNT_COLLATERAL);

    }
}
