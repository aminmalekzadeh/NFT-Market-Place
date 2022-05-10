// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMarketOwner.sol";
import "./LibTransfer.sol";
import "./LibAsset.sol";

abstract contract MarketOwner is IMarketOwner, Ownable  {

  uint protcolfee;
  using LibTransfer for address;

  function updateFeeMarket(uint _fee) override public onlyOwner {
      protcolfee = _fee;
  }

  function TransferFeeMarketOwner(LibAsset.AssetType memory _assettype) override public {
      if(_assettype.assetClass == LibAsset.ERC20_ASSET_CLASS){
          IERC20(_assettype.assetClass).transfer(owner());
      } else if(_assettype.assetClass == LibAsset.ETH_ASSET_CLASS){
          address(owner()).transferEth(protcolfee);
      }
  }

}
