// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Validate.sol";

abstract contract Bids is Validate {

   Counters.Counter private _itemBidCounter;

   mapping(uint256 => BidList) private bidItems;

   struct BidList {
    uint id;
    uint marketItemId;
    uint256 tokenId;
    uint256 bidPrice;
    address nftContract;
    address bidder;
    address seller;
    bool isAccepted;
   }

   event bidToItem (
    uint indexed id,
    address indexed nftContract,
    uint256 indexed tokenId,
    address bidder,
    address seller,
    uint256 price,
    bool isAccepted
  );

    function setBid(BidList _bidItem) external {
        Order storage marketitem = marketItems[_bidItem.marketItemId];
        require(_bidItem.marketItemId == marketitem.id , "Not found this item in market");
        Validate(marketItems[_marketItemId]);
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

    function getBids() external view returns(BidList[] memory) {
        uint256 total = _itemBidCounter.current();
        uint itemCount = 0;
        for (uint256 i = 0; i <= total; i++){
         itemCount++;
        }
    
        uint index = 0;
        BidList[] memory items = new BidList[](itemCount);
        for (uint i = 1; i <= total; i++) {
            items[index] = bidItems[i];
            index ++;
        }
        return items;
    }

    function getTotalBids() public view returns (uint256) { return _itemBidCounter.current(); }

    function acceptBidByOwner(uint256 _bidItemId) public {
        BidList storage Biditem = bidItems[_bidItemId];
        Order storage marketitem = marketItems[Biditem.marketItemId];
        require(IERC721(Biditem.nftContract).ownerOf(Biditem.tokenId) == address(msg.sender) , "you should be owner this token id");
        require(IERC721(Biditem.nftContract).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
        checkBalanceERC20(marketitem.ERC20Token,marketitem.price, address(Biditem.bidder));

        TokenERC721 tokenERC721 = TokenERC721(Biditem.nftContract);
        (address receiver, uint royalityAmount) = tokenERC721.royalityInfo(Biditem.tokenId, Biditem.bidPrice);
    
        recieverRoyalty = payable(receiver);
        IERC721(Biditem.nftContract).transferFrom(msg.sender, Biditem.bidder, Biditem.tokenId);
    
        uint cost = Biditem.bidPrice - royalityAmount;
        IERC20(marketitem.ERC20Token).transferFrom(Biditem.bidder, recieverRoyalty, royalityAmount);
        IERC20(marketitem.ERC20Token).transferFrom(Biditem.bidder, marketitem.seller, cost);

        marketitem.buyer = payable(Biditem.bidder);
        marketitem.state = State.Release;
        _itemSoldCounter.increment();   
        Biditem.isAccepted = true; 
    }
}