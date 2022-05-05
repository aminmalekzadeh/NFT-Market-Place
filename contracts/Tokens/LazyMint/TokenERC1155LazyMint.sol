// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../royalties/impl/RoyaltiesV2impl.sol";
import "../../royalties/LibRoyality.sol";
import "../../royalties/LibRoyaltiesV2.sol";

contract TokenERC1155LazyMint is ERC1155, ERC1155Burnable,  Ownable, RoyaltiesV2Impl {

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address public contractAddress;
    string TokenURI;
    string contracturi;
    mapping(uint256 => uint256) public tokenIds;
    mapping (uint256 => string) public _tokenURIs;

    string private _baseURI;

    struct NFTVoucher {
        uint256 tokenId;
        uint256 minPrice;
        uint256 supply;
        string uri;
    }

    constructor(string memory _uri, address contractAddr) ERC1155(_uri) {
        TokenURI = _uri;
        contractAddress = contractAddr;
        contracturi = _uri;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, string memory _uri,bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
        tokenIds[id] = id;
        setTokenURI(id, _uri);
        setApprovalForAll(contractAddress, true);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
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

    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        string memory __tokenURI = _tokenURIs[tokenId];
        return string(abi.encodePacked(__tokenURI));
    }

    function setTokenURI(uint256 tokenId, string memory _uri) public onlyOwner {
        _tokenURIs[tokenId] = _uri;
        emit URI(_tokenURI(tokenId), tokenId);
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