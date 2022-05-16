// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./LibAsset.sol";
import "./LibTransfer.sol";
import "./State.sol";
import "./interface/IOrder.sol";

library Order {

  struct OrderItem {
    uint id;
    address payable seller;
    LibAsset.Asset sellerAsset;
    address payable buyer;
    LibAsset.Asset buyerAsset;
    uint start;
    uint end;
    State.stateItem state;
  }


  function isApproved(LibAsset.Asset memory _asset) internal view {

    (address token, uint tokenId) = abi.decode(_asset.assetType.data, (address, uint));
    if(_asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS){
      require(IERC721(token).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
    }else if (_asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
      require(_asset.value <= IERC1155(token).balanceOf(msg.sender, tokenId), "You don't have amount enough of this token");
      require(IERC1155(token).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
    }

  }
    
}