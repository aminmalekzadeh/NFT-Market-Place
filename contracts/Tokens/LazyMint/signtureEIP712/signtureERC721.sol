// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library signtureERC721 {

    struct NFTVoucher {
        uint256 tokenId;
        uint256 minPrice;
        string uri;
    }


    function _hashDomain() internal view returns (bytes32) {
        return keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes("LazyNFT-Voucher")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
           )
        );  
    }


  function _verify(
    uint8 v,
    bytes32 r,
    bytes32 s,
    NFTVoucher calldata voucher
  ) public view returns(address) {
    bytes32 eip712DomainHash = _hashDomain();
    bytes32 hashStruct = keccak256(abi.encode(
           keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
           voucher.tokenId,
           voucher.minPrice,
           keccak256(bytes(voucher.uri))
        ));

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    address signer = ecrecover(hash, v, r, s);
    return signer;
  }
}
