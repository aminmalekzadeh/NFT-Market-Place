// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "./Order.sol";
import "../NFTexchangeCore.sol";


library State {

    enum stateItem { Created, Release, Inactive }

    function setState(Order.OrderItem memory _order, stateItem _state) external pure {
        _order.state = _state;
    }

    // function getState(uint memory _ordeId, address _contract) external view returns(State) {
    //     e = NFTexchange(_contract);
    //     return e.orderItems[_ordeId].state;
    // }
}