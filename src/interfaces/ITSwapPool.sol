// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

//why are we using only the price of a pool tokne in weth?
interface ITSwapPool {
    function getPriceOfOnePoolTokenInWeth() external view returns (uint256);
}
