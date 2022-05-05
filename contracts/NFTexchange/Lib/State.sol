// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "./Order.sol";
import "../NFTexchange.sol";

abstract contract State {

    enum State { Created, Release, Inactive }
    NFTexchange e;

    function setState(uint memory _ordeId, State _state, address _contract) external {
        e = NFTexchange(_contract);
        Order storage item = e.orderItems[_ordeId];
        item.state = _state;
    }

    function getState(uint memory _ordeId, address _contract) external view returns(State) {
        e = NFTexchange(_contract);
        return e.orderItems[_ordeId].state;
    }
}