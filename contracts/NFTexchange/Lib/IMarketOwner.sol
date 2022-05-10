// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "./LibAsset.sol";

interface IMarketOwner {

    function updateFeeMarket(uint _fee) external ;
    
    function TransferFeeMarketOwner(LibAsset.AssetType memory _assettype) external;
}