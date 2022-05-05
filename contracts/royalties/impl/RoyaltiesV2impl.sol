// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "./AbstractRoyalties.sol";
import "../RoyaltiesV2.sol";

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {

    function getRaribleV2Royalties(uint256 id) override external view returns (LibRoyality.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibRoyality.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }
}