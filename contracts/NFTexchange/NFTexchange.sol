// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Lib/LibAsset.sol";
import "./Lib/LibTransfer.sol";
import "./Lib/Order.sol";
import "../TokenERC721.sol";
import "../TokenERC1155.sol";

contract NFTexchange is ReentrancyGuard, Order {
  
  using Counters for Counters.Counter;
  using SafeMath for uint;
  Counters.Counter private _itemCounter; //start from 1
  Counters.Counter private _itemSoldCounter;
  Counters.Counter private _itemBidCounter;

  address payable public marketowner;
  address payable recieverRoyalty;

  mapping(uint256 => Order) public orderItems;   


  // constructor() public {
  //    marketowner = payable(msg.sender);
  // }

  function addBidToNFT(uint _marketItemId, uint256 _tokenId, uint256 _bidPrice, address _nftContract)
  public returns(uint itemId) {
    Order storage marketitem = marketItems[_marketItemId];
    require(_marketItemId == marketitem.id , "Not found this item in market");
    validateTimeAuction(marketItems[_marketItemId]);
    _itemBidCounter.increment();
    uint256 id = _itemBidCounter.current();
    bidItems[id] = BidList(
      id,
      _marketItemId,
      _tokenId,
      _bidPrice,
      _nftContract,
      address(msg.sender),
      marketitem.seller,
      false
    );

    itemId = id;

    emit bidToItem(
      id,
      _nftContract,
      _tokenId,
      address(msg.sender),
      marketitem.seller,
      _bidPrice,
      false
    );
  }

  function checkBalanceERC20(address ERC20Token, uint256 price, address buyer) public view {
    uint256 balance = IERC20(ERC20Token).balanceOf(buyer);
    require(price < balance, "you don't have token ERC20 enough");
  } 

  function LastIdMarketItem() public view returns(uint256){
    return _itemCounter.current();
  }

  function LastIdBidsItem() public view returns(uint256){
    return _itemBidCounter.current();
  }

  

  function deleteMarketItem(uint256 itemId) public nonReentrant {
    require(itemId <= _itemCounter.current(), "id must <= item count");
    require(marketItems[itemId].state == State.Created, "item must be on market");
    Order storage item = marketItems[itemId];

    if(item.amount == 0){
      require(IERC721(item.nftContract).ownerOf(item.tokenId) == msg.sender, "must be the owner");
      require(IERC721(item.nftContract).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
    }else {
      require(item.amount <= IERC1155(item.nftContract).balanceOf(msg.sender, item.tokenId), "You don't have amount enough of this token");
      require(IERC1155(item.nftContract).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
    }
    
    item.state = State.Inactive;

    emit MarketItemSold(
      itemId,
      item.nftContract,
      item.tokenId,
      item.seller,
      address(0),
      item.amount,
      0,
      State.Inactive
    );

  }

  function createMarketSaleERC721(
    address nftContract,
    uint256 id
  ) public payable nonReentrant {

    Order storage item = marketItems[id]; //should use storge!!!!
    uint price = item.price;
    uint tokenId = item.tokenId;
    address ERC20Token = item.ERC20Token;

    validateFixPrice(item);

    if(address(0) == ERC20Token){
     require(msg.value == price, "Please submit the asking price");
    }else {
      require(checkBalanceERC20(ERC20Token,price,address(msg.sender)));
    }

    require(IERC721(nftContract).isApprovedForAll(item.seller, address(this)), "NFT must be approved to market");

    TokenERC721 tokenERC721 = TokenERC721(nftContract);
    (address receiver, uint royalityAmount) = tokenERC721.royalityInfo(tokenId, price);
    
    recieverRoyalty = payable(receiver);
    IERC721(nftContract).transferFrom(item.seller, msg.sender, tokenId);
    
    uint cost = price - royalityAmount;
    if(address(0) == ERC20Token){
     item.seller.transfer(msg.value.sub(royalityAmount));
     transferEth(recieverRoyalty, royalityAmount);
    }else{
      IERC20(ERC20Token).transferFrom(msg.sender, recieverRoyalty, royalityAmount);
      IERC20(ERC20Token).transferFrom(msg.sender, item.seller, cost);
    }

    item.buyer = payable(msg.sender);
    item.state = State.Release;
    _itemSoldCounter.increment();    

    emit MarketItemSold(
      id,
      nftContract,
      tokenId,
      item.seller,
      msg.sender,
      0,
      price,
      State.Release
    );    
  }

  function transferEth(address to, uint value) public {
      (bool success,) = to.call{ value: value }("");
      require(success, "transfer failed");
  }

  function createMarketSaleERC1155(
    address nftContract,
    uint256 id,
    uint amount
  ) public payable nonReentrant {

    Order storage item = marketItems[id]; //should use storge!!!!
    uint price = item.price;
    uint tokenId = item.tokenId;
    address ERC20Token = item.ERC20Token;

    require(amount <= IERC1155(nftContract).balanceOf(item.seller, tokenId), "You don't have amount enough of this token");
    validateFixPrice(item);

    if(address(0) == ERC20Token){
     require(msg.value == price, "Please submit the asking price");
    }else {
      require(checkBalanceERC20(ERC20Token,price,address(msg.sender)));
    }

    require(IERC1155(nftContract).isApprovedForAll(item.seller, address(this)), "NFT must be approved to market");

    TokenERC1155 token1155 = TokenERC1155(nftContract);
    (address receiver, uint royalityAmount) = token1155.royalityInfo(tokenId, price);
    
    recieverRoyalty = payable(receiver);
    IERC1155(nftContract).safeTransferFrom(item.seller, msg.sender, tokenId, amount, "");
    
    uint cost = price - royalityAmount;
    if(address(0) == ERC20Token){
     item.seller.transfer(msg.value.sub(royalityAmount));
     transferEth(recieverRoyalty, royalityAmount);
    }else{
      IERC20(ERC20Token).transferFrom(msg.sender, recieverRoyalty, royalityAmount);
      IERC20(ERC20Token).transferFrom(msg.sender, item.seller, cost);
    }

    item.buyer = payable(msg.sender);
    item.state = State.Release;
    _itemSoldCounter.increment();    

    emit MarketItemSold(
      id,
      nftContract,
      tokenId,
      item.seller,
      msg.sender,
      amount,
      price,
      State.Release
    );    
  }


  

  function fetchActiveItems() public view returns (Order[] memory) {
    return fetchHepler(FetchOperator.ActiveItems);
  }

  /**
   * @dev Returns only market items a user has purchased
   * todo pagination
   */
  function fetchMyPurchasedItems() public view returns (Order[] memory) {
    return fetchHepler(FetchOperator.MyPurchasedItems);
  }

  /**
   * @dev Returns only market items a user has created
   * todo pagination
  */
  function fetchMyCreatedItems() public view returns (Order[] memory) {
    return fetchHepler(FetchOperator.MyCreatedItems);
  }

  enum FetchOperator { ActiveItems, MyPurchasedItems, MyCreatedItems}

  /**
   * @dev fetch helper
   * todo pagination   
   */
   function fetchHepler(FetchOperator _op) private view returns (Order[] memory) {     
    uint total = _itemCounter.current();

    uint itemCount = 0;
    for (uint i = 1; i <= total; i++) {
      if (isCondition(marketItems[i], _op)) {
        itemCount ++;
      }
    }

    uint index = 0;
    Order[] memory items = new Order[](itemCount);
    for (uint i = 1; i <= total; i++) {
      if (isCondition(marketItems[i], _op)) {
        items[index] = marketItems[i];
        index ++;
      }
    }
    return items;
  } 

  /**
   * @dev helper to build condition
   *
   * todo should reduce duplicate contract call here
   * (IERC721(item.nftContract).getApproved(item.tokenId) called in two loop
   */
  function isCondition(Order memory item, FetchOperator _op) private view returns (bool){
    if(_op == FetchOperator.MyCreatedItems){ 
      return 
        (item.seller == msg.sender
          && item.state != State.Inactive
        )? true
         : false;
    }else if(_op == FetchOperator.MyPurchasedItems){
      return
        (item.buyer == msg.sender) ? true: false;
    }else if(_op == FetchOperator.ActiveItems){
      if(item.amount == 0){
      return 
        (item.buyer == address(0) 
          && item.state == State.Created
          && (IERC721(item.nftContract).getApproved(item.tokenId) == address(this))
        )? true
         : false;
      }else{
        return 
        (item.buyer == address(0) 
          && item.state == State.Created
          && IERC1155(item.nftContract).isApprovedForAll(item.seller, address(this))
        ) ? true
         : false;
      }
      
    }else{
      return false;
    }
  }

}
