// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

interface IMarketOwner {

    function updateFeeMarket(uint _fee) external pure;
    
    function TransferFeeMarketOwner(address _feereciever) external;
}