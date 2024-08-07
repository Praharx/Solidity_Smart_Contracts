// SPDX-License-Identifier:MIT
// invariants aka the properties that will always hold true.

// What are those invariant properties for this function?
// 1.The total supply of CSD Coins should be less than the total collateral value.
// 2.Getter view functions should never revert <-- evergreen test

pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployCSD} from "../../script/DeployCSD.s.sol";
import {CSDEngine} from "../../src/CSDEngine.sol";
import {DStableCoin} from "../../src/DStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzepplin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant,Test{
    DeployCSD deployer;
    CSDEngine csd_engine;
    DStableCoin csd_coin;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external{
        deployer = new DeployCSD();
        (csd_coin,csd_engine,config) = deployer.run();
        (,,weth,wbtc,) = config.activeNetworkConfig();
        // targetContract(address(csd_engine));
        handler = new Handler(csd_engine,csd_coin);
        targetContract(address(handler));
    }
    
    function invariant_ProtocolMustHaveMoreTotalCollateralThanTotalSupply() public view{
        // get all the value of collateral in csd_engine contract and compare it to debt.
        uint totalSupply = csd_coin.totalSupply();
        uint totalWethDeposited = IERC20(weth).balanceOf(address(csd_engine));
        uint totalWBtcDeposited = IERC20(wbtc).balanceOf(address(csd_engine));

        uint wethValue = csd_engine.getUsdValue(weth, totalWethDeposited);
        uint wbtcValue = csd_engine.getUsdValue(wbtc, totalWBtcDeposited);

        console.log("weth value:",wethValue);
        console.log("wbtc value:", wbtcValue);
        console.log("total supply:",totalSupply);

        assert(wethValue + wbtcValue >= totalSupply);
    }
}