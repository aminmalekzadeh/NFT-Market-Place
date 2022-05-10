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
import "./Lib/MarketOwner.sol";
import "./Lib/Order.sol";
import "./Lib/State.sol";
import "./Lib/Validate.sol";
import "./Lib/interface/ITransferManager.sol";
// import "./Lib/TransferManager.sol";
import "./Lib/interface/IOrder.sol";
import "../royalties/IERC2981Royalties.sol";


contract NFTexchange is ReentrancyGuard, Validate, MarketOwner {
  
  using Counters for Counters.Counter;
  using SafeMath for uint;
  Counters.Counter private _itemCounter; //start from 1
  Counters.Counter private _itemSoldCounter;

  address payable recieverRoyalty;

      
  using LibTransfer for address;
  uint fee;

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

  function marketSale(uint256 marketItemId, LibAsset.Asset memory _asset) public payable nonReentrant  {
    Order.OrderItem storage item = orderItems[marketItemId];
    checkStatusItem(item);
    validateOrder(item);
    LibAsset.Asset memory matchNFT = item.sellerAsset;
    if(matchNFT.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS || matchNFT.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS){
        (address token, uint tokenId) = abi.decode(matchNFT.assetType.data, (address, uint));
        doTransfer(item, _asset);
    }
  } 



   function doTransfer(Order.OrderItem memory order, LibAsset.Asset memory _assetBuyer) private {
        LibAsset.Asset memory buyerAsset = order.buyerAsset;
        LibAsset.Asset memory sellerAsset = order.sellerAsset;
        (address token, uint tokenId) = abi.decode(sellerAsset.assetType.data, (address, uint));
        if(sellerAsset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS){
           IERC721(token).safeTransferFrom(order.seller, order.buyer, tokenId);
        }else if(sellerAsset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS){
           IERC1155(token).safeTransferFrom(order.seller, order.buyer, tokenId, sellerAsset.value,
           "0x00");
           if(_assetBuyer.assetType.assetClass == buyerAsset.assetType.assetClass){
               if(_assetBuyer.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS){
                (address tokenAddress) = abi.decode(_assetBuyer.assetType.data, (address));
                IERC20(tokenAddress).transfer(order.seller, _assetBuyer.value);
               }else if(_assetBuyer.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
                address(order.seller).transferEth(_assetBuyer.value);
               }
            }
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

}
