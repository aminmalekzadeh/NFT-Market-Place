// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../royalties/impl/RoyaltiesV2impl.sol";
import "../royalties/LibRoyality.sol";
import "../royalties/LibRoyaltiesV2.sol";

contract TokenERC1155LazyMint is ERC1155, ERC1155Burnable,  Ownable, RoyaltiesV2Impl {

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address public contractAddress;
    string TokenURI;
    string contracturi;
    mapping (uint256 => string) public _tokenURIs;


    constructor(string memory _uri, address contractAddr) ERC1155(_uri) {
        TokenURI = _uri;
        contractAddress = contractAddr;
    }

    function mint(address account, uint256 id, uint256 amount, string memory _uri,bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
        setTokenURI(id, _uri);
        setApprovalForAll(contractAddress, true);
    }

    //configure royalties for Rariable
    function setRoyalities(
        uint256 _tokenId,
        address payable _roalitiesRecipentAddress,
        uint96 _percentageBasicPoints
    ) public onlyOwner {
        LibRoyality.Part[] memory _royalities = new LibRoyality.Part[](1);
        _royalities[0].value = _percentageBasicPoints;
        _royalities[0].account = _roalitiesRecipentAddress;
        _saveRoyalties(_tokenId, _royalities);
    }

    function royalityInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royalityAmount)
    {
        LibRoyality.Part[] memory _royalities = royalties[_tokenId];
        if (_royalities.length > 0) {
            return (
                _royalities[0].account,
                (_salePrice * _royalities[0].value) / 10000
            );
        }
        return (address(0), 0);
    }

    function setTokenURI(uint256 tokenId, string memory _uri) public onlyOwner {
        _tokenURIs[tokenId] = _uri;
        emit URI(uri(tokenId), tokenId);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if(interfaceId == _INTERFACE_ID_ERC2981) {
          return true;
        }

        return super.supportsInterface(interfaceId);
    }
}