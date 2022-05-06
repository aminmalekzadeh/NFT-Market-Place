// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMarketOwner.sol";
import "./LibAsset.sol";
import "./Order.sol";


abstract contract TransferManager is Ownable, IMarketOwner, ITransferManager {
    
    using LibTransfer for address;
    uint fee;

    // function updateFeeMarket(uint _fee) external pure {
    //     fee = _fee;
    // }

    // function CalculateFeeMarket(uint _salePrice) private pure returns(uint) {
    //     return _salePrice - fee;
    // }

    function doTransfer(Order.OrderItem memory order, LibAsset.Asset memory _assetBuyer) external virtual payable {
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
    
}