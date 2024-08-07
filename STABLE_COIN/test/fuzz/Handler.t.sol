// Handler is used to narrow down the function call.
//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {CSDEngine} from "../../src/CSDEngine.sol";
import {DStableCoin} from "../../src/DStableCoin.sol";
import {ERC20Mock} from "@openzepplin/contracts/mocks/ERC20Mock.sol";

contract Handler is Test {
    CSDEngine csd_engine;
    DStableCoin csd_coin;
    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(CSDEngine _csd_engine, DStableCoin _csd_coin) {
        csd_engine = _csd_engine;
        csd_coin = _csd_coin;

        address[] memory collateralTokens = csd_engine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    } 

    // redeem collateral
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public{
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral,1,MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender,amountCollateral);
        collateral.approve(address(csd_engine),amountCollateral);
        csd_engine.depositCollateral(address(collateral),amountCollateral);
        vm.stopPrank();
    }

    function redeemCollateral(uint collateralSeed,uint amountCollateral) public{
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = csd_engine.getCollateralBalanceOfUser(address(collateral),msg.sender);
        amountCollateral = bound(amountCollateral,1,maxCollateralToRedeem);
        csd_engine.redeemCollateral(address(collateral),amountCollateral);
    }

    //private functions
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if(collateralSeed % 2 ==0){
            return weth;
        }
        return wbtc;
    }
}