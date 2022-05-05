// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
pragma abicoder v2;

import "./LibRoyality.sol";

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibRoyality.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibRoyality.Part[] memory);
}