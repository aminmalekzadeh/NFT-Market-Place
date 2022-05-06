// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "../LibAsset.sol";
import "../Order.sol";

abstract contract ITransferManager {

  
  function doTransfer(Order.OrderItem memory _order, LibAsset.AssetType memory _assetBuyer) external virtual payable;

}