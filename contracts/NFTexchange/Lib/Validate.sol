// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "./Order.sol";
import "./State.sol";

abstract contract Validate is State {

  function validateOrder(Order memory order) internal view {
      require(orderItems[order.id].state == State.Created, "You can't interact with this order");
      require(order.start == 0 || order.start < block.timestamp, "Order start validation failed");
      require(order.end == 0 || order.end > block.timestamp, "Order end validation failed");
  }
}