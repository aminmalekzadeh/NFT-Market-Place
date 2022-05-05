// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "./LibAsset.sol";
import "./LibTransfer.sol";
import "./State.sol";

abstract contract Order {

  struct Order {
    uint id;
    address payable seller;
    LibAsset.Asset sellerAsset;
    address payable buyer;
    LibAsset.Asset buyerAsset;
    uint start;
    uint end;
    State state;
  }

  event MarketItemCreated (
    uint indexed id,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address buyer,
    address ERC20Token,
    uint amount,
    uint start,
    uint end,
    uint256 price,
    State state
   );

  event MarketItemSold (
    uint indexed id,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address buyer,
    uint amount,
    uint256 price,
    State state
  );


  function createMarketItem(Order memory _order) public payable nonReentrant {

    require(price > 0, "Price must be at least 1 wei");

    _itemCounter.increment();
    uint256 id = _itemCounter.current();

    marketItems[id] =  Order(
      id,
      _order.nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      ERC20Token,
      amount,
      start,
      end,
      price,
      State.Created
    );

    if(amount == 0){
      require(IERC721(nftContract).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
    }else{
      require(amount <= IERC1155(nftContract).balanceOf(msg.sender, tokenId), "You don't have amount enough of this token");
      require(IERC1155(nftContract).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
    }
    
    emit MarketItemCreated(
      id,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      ERC20Token,
      amount,
      start,
      end,
      price,
      State.Created
    );
  }
    
}