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
import "./Lib/State.sol";
import "./Lib/Validate.sol";
import "./Lib/interface/ITransferManager.sol";
import "./Lib/interface/IOrder.sol";
import "../royalties/IERC2981Royalties.sol";


contract NFTexchange is ReentrancyGuard, Validate {
  
  using Counters for Counters.Counter;
  using SafeMath for uint;
  Counters.Counter private _itemCounter; //start from 1
  Counters.Counter private _itemSoldCounter;

  address payable public marketowner;
  address payable recieverRoyalty;

  Order.OrderItem order;

  mapping(uint256 => Order.OrderItem) private orderItems;

  event MarketItemCreated (
    uint indexed id,
    address seller,
    LibAsset.Asset sellerAsset,
    address buyer,
    LibAsset.Asset buyerAsset,
    uint start,
    uint end,
    State.stateItem state
  );

  event MarketItemSold (
    uint indexed id,
    address seller,
    LibAsset.Asset sellerAsset,
    address buyer,
    LibAsset.Asset buyerAsset,
    State.stateItem state
  );


   function createMarketItem(Order.OrderItem memory _order) public {

     Order.isApproved(_order.sellerAsset);

     _itemCounter.increment();
     uint256 id = _itemCounter.current();

     orderItems[id] = Order.OrderItem(
      id,
      payable(msg.sender),
      _order.sellerAsset,
      payable(address(0)),
      _order.buyerAsset,
      _order.start,
      _order.end,
      State.stateItem.Created
     );
    
    emit MarketItemCreated(
      id,
      msg.sender,
      _order.sellerAsset,
      address(0),
      _order.buyerAsset,
      _order.start,
      _order.end,
      State.stateItem.Created
    );
  }  


  function checkStatusItem(Order.OrderItem memory _order) private view {
    require(orderItems[_order.id].state == State.stateItem.Created, "You can't interact with this order");
  }
  

//   function deleteMarketItem(uint256 itemId) public nonReentrant {
//     require(itemId <= _itemCounter.current(), "id must <= item count");
//     require(orderItems[itemId].state == State.Created, "item must be on market");
//     Order storage item = orderItems[itemId];

//     if(item.amount == 0){
//       require(IERC721(item.nftContract).ownerOf(item.tokenId) == msg.sender, "must be the owner");
//       require(IERC721(item.nftContract).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
//     }else {
//       require(item.amount <= IERC1155(item.nftContract).balanceOf(msg.sender, item.tokenId), "You don't have amount enough of this token");
//       require(IERC1155(item.nftContract).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
//     }
    
//     item.state = State.Inactive;

//     emit MarketItemSold(
//       itemId,
//       item.nftContract,
//       item.tokenId,
//       item.seller,
//       address(0),
//       item.amount,
//       0,
//       State.Inactive
//     );

//   }

  function marketSale(uint256 marketItemId, LibAsset.AssetType memory _assetType) public payable nonReentrant  {
    Order.OrderItem storage item = orderItems[marketItemId];
    checkStatusItem(item);
    validateOrder(item);
    LibAsset.Asset memory matchNFT = item.sellerAsset;
    if(matchNFT.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS || matchNFT.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS){
        (address token, uint tokenId) = abi.decode(matchNFT.assetType.data, (address, uint));
        // doTransfer(item, _assetType);
    }
  } 

//   function createMarketSaleERC721(
//     uint256 marketItemId
//   ) public payable nonReentrant {

//     uint price = item.price;
//     uint tokenId = item.tokenId;
//     address ERC20Token = item.ERC20Token;


//     if(address(0) == ERC20Token){
//      require(msg.value == price, "Please submit the asking price");
//     }else {
//       checkBalanceERC20(ERC20Token,price,address(msg.sender));
//     }

//     require(IERC721(nftContract).isApprovedForAll(item.seller, address(this)), "NFT must be approved to market");

//     TokenERC721 tokenERC721 = TokenERC721(nftContract);
//     (address receiver, uint royalityAmount) = tokenERC721.royalityInfo(tokenId, price);
    
//     recieverRoyalty = payable(receiver);
//     IERC721(nftContract).transferFrom(item.seller, msg.sender, tokenId);
    
//     uint cost = price - royalityAmount;
//     if(address(0) == ERC20Token){
//      item.seller.transfer(msg.value.sub(royalityAmount));
//      transferEth(recieverRoyalty, royalityAmount);
//     }else{
//       IERC20(ERC20Token).transferFrom(msg.sender, recieverRoyalty, royalityAmount);
//       IERC20(ERC20Token).transferFrom(msg.sender, item.seller, cost);
//     }

//     item.buyer = payable(msg.sender);
//     item.state = State.Release;
//     _itemSoldCounter.increment();    

//     emit MarketItemSold(
//       id,
//       nftContract,
//       tokenId,
//       item.seller,
//       msg.sender,
//       0,
//       price,
//       State.Release
//     );    
//   }


//   function createMarketSaleERC1155(
//     address nftContract,
//     uint256 id,
//     uint amount
//   ) public payable nonReentrant {

//     Order storage item = marketItems[id]; //should use storge!!!!
//     uint price = item.price;
//     uint tokenId = item.tokenId;
//     address ERC20Token = item.ERC20Token;

//     require(amount <= IERC1155(nftContract).balanceOf(item.seller, tokenId), "You don't have amount enough of this token");
//     validateFixPrice(item);

//     if(address(0) == ERC20Token){
//      require(msg.value == price, "Please submit the asking price");
//     }else {
//       require(checkBalanceERC20(ERC20Token,price,address(msg.sender)));
//     }

//     require(IERC1155(nftContract).isApprovedForAll(item.seller, address(this)), "NFT must be approved to market");

//     TokenERC1155 token1155 = TokenERC1155(nftContract);
//     (address receiver, uint royalityAmount) = token1155.royalityInfo(tokenId, price);
    
//     recieverRoyalty = payable(receiver);
//     IERC1155(nftContract).safeTransferFrom(item.seller, msg.sender, tokenId, amount, "");
    
//     uint cost = price - royalityAmount;
//     if(address(0) == ERC20Token){
//      item.seller.transfer(msg.value.sub(royalityAmount));
//      transferEth(recieverRoyalty, royalityAmount);
//     }else{
//       IERC20(ERC20Token).transferFrom(msg.sender, recieverRoyalty, royalityAmount);
//       IERC20(ERC20Token).transferFrom(msg.sender, item.seller, cost);
//     }

//     item.buyer = payable(msg.sender);
//     item.state = State.Release;
//     _itemSoldCounter.increment();    

//     emit MarketItemSold(
//       id,
//       nftContract,
//       tokenId,
//       item.seller,
//       msg.sender,
//       amount,
//       price,
//       State.Release
//     );    
//   }


  

//   function fetchActiveItems() public view returns (Order.OrderItem[] memory) {
//     return fetchHepler(FetchOperator.ActiveItems);
//   }

//   /**
//    * @dev Returns only market items a user has purchased
//    * todo pagination
//    */
//   function fetchMyPurchasedItems() public view returns (Order.OrderItem[] memory) {
//     return fetchHepler(FetchOperator.MyPurchasedItems);
//   }

//   /**
//    * @dev Returns only market items a user has created
//    * todo pagination
//   */
//   function fetchMyCreatedItems() public view returns (Order.OrderItem[] memory) {
//     return fetchHepler(FetchOperator.MyCreatedItems);
//   }

//   enum FetchOperator { ActiveItems, MyPurchasedItems, MyCreatedItems}

  /**
   * @dev fetch helper
   * todo pagination   
   */
//    function fetchHepler(FetchOperator _op) private view returns (Order.OrderItem[] memory) {     
//     uint total = _itemCounter.current();

//     uint itemCount = 0;
//     for (uint i = 1; i <= total; i++) {
//       if (isCondition(orderItems[i], _op)) {
//         itemCount ++;
//       }
//     }

//     uint index = 0;
//     Order.OrderItem[] memory items = new Order.OrderItem[](itemCount);
//     for (uint i = 1; i <= total; i++) {
//       if (isCondition(orderItems[i], _op)) {
//         items[index] = orderItems[i];
//         index ++;
//       }
//     }
//     return items;
//   } 

  /**
   * @dev helper to build condition
   *
   * todo should reduce duplicate contract call here
   * (IERC721(item.nftContract).getApproved(item.tokenId) called in two loop
   */
//   function isCondition(Order.OrderItem memory item, FetchOperator _op) private view returns (bool){
//     if(_op == FetchOperator.MyCreatedItems){ 
//       return 
//         (item.seller == msg.sender
//           && item.state != State.stateItem.Inactive
//         )? true
//          : false;
//     }else if(_op == FetchOperator.MyPurchasedItems){
//       return
//         (item.buyer == msg.sender) ? true: false;
//     }else if(_op == FetchOperator.ActiveItems){
//       if(item.amount == 0){
//       return 
//         (item.buyer == address(0) 
//           && item.state == State.Created
//           && (IERC721(item.nftContract).getApproved(item.tokenId) == address(this))
//         )? true
//          : false;
//       }else{
//         return 
//         (item.buyer == address(0) 
//           && item.state == State.Created
//           && IERC1155(item.nftContract).isApprovedForAll(item.seller, address(this))
//         ) ? true
//          : false;
//       }
      
//     }else{
//       return false;
//     }
//   }

}
