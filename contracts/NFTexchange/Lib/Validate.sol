// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Order.sol";
import "./State.sol";

abstract contract Validate {

  function validateOrder(Order.OrderItem memory order) internal view {
      require(order.start == 0 || order.start < block.timestamp, "Order start validation failed");
      require(order.end == 0 || order.end > block.timestamp, "Order end validation failed");
  }

  function checkBalanceERC20(address ERC20Token, uint256 price, address buyer) public view {
    uint256 balance = IERC20(ERC20Token).balanceOf(buyer);
    require(price < balance, "you don't have token ERC20 enough");
  } 
}