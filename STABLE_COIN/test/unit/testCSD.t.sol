//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
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
    address weth;

    address public USER = makeAddr("user");
    uint256 AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployCSD();
        (dStableCoin, csd_engine, config) = deployer.run();
        (wethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    ///////////////////// PRICE TESTS /////////////////////

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        // 15e18 * 2000/eth = 30000e18
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = csd_engine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    ///////////////////// PRICE TESTS /////////////////////

    function testRevertsWhenAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(csd_engine), AMOUNT_COLLATERAL);

        vm.expectRevert(CSDEngine.CSDEngine__AmountIsZero.selector);
        csd_engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}
