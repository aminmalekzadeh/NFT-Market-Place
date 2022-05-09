// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

abstract contract signtureERC721 is EIP712 {
    using ECDSA for bytes32;


    struct NFTVoucher {
        uint256 tokenId;
        uint256 minPrice;
        string uri;
    }

    constructor ()
     EIP712("LazyNFT-Voucher", "1") 
    {
      
    }

    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
           keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
           voucher.tokenId,
           voucher.minPrice,
           keccak256(bytes(voucher.uri))
        )));
    }


    function _verify(NFTVoucher calldata voucher, bytes memory signature) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return digest.toEthSignedMessageHash().recover(signature);
    }

}
