// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "../LibAsset.sol";

abstract contract IOrder {

  function isApproved(LibAsset.Asset memory _asset) internal virtual;

}