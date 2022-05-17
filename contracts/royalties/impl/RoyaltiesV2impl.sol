// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "./AbstractRoyalties.sol";
import "../RoyaltiesV2.sol";
import "../IERC2981Royalties.sol";

contract RoyaltiesV2impl is AbstractRoyalties, RoyaltiesV2, IERC2981Royalties {

    function getRaribleV2Royalties(uint256 id) override external view returns (LibRoyality.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibRoyality.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _value)
        override
        external
        view
        returns (address _receiver, uint256 _royaltyAmount)
    {
        LibRoyality.Part[] memory _royalities = royalties[_tokenId];
        if (_royalities.length > 0) {
            return (
                _royalities[0].account,
                (_value * _royalities[0].value) / 10000
            );
        }
        return (address(0), 0);
    }
}