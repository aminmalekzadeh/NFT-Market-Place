// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IMarketOwner.sol";
import "./LibTransfer.sol";
import "./LibAsset.sol";

abstract contract MarketOwner is IMarketOwner, Ownable  {

  uint protcolfee;
  using LibTransfer for address;  

  // it should set a percent from 10000
  function updateFeeMarket(uint _fee) override public onlyOwner {
      protcolfee = _fee;
  }

  function TransferFeeMarketOwner(LibAsset.Asset memory _asset) override public {
      if(_asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS){
          (address tokenAddress) = abi.decode(_asset.assetType.data, (address));
          uint256 calFee = (_asset.value * protcolfee) / 10000;
          IERC20(tokenAddress).transferFrom(msg.sender, owner(), calFee);
      } else if(_asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS){
          uint256 calFee = (_asset.value * protcolfee) / 10000;
          address(owner()).transferEth(calFee);
      }
  }

}
