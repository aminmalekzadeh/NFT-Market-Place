// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "./Order.sol";

library State {

    enum stateItem { Created, Release, Inactive }

    function setState(Order.OrderItem memory _order, stateItem _state) external pure {
        _order.state = _state;
    }
}