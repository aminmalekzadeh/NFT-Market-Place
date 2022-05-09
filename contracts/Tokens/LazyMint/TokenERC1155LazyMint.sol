// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../royalties/impl/RoyaltiesV2Impl.sol";
import "./signtureEIP712/signtureERC1155.sol";
import "../../royalties/LibRoyality.sol";
import "../../royalties/LibRoyaltiesV2.sol";

contract TokenERC1155LazyMint is ERC1155, ERC1155Burnable, Ownable, AccessControl, RoyaltiesV2Impl, signtureERC1155 {

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address public contractAddress;
    string TokenURI;
    string contracturi;
    mapping(uint256 => uint256) public tokenIds;
    mapping (uint256 => string) public _tokenURIs;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _baseURI;

    constructor(string memory _uri, address minter, address contractAddr) ERC1155(_uri) {
        _setupRole(MINTER_ROLE, minter);
        TokenURI = _uri;
        contractAddress = contractAddr;
        contracturi = _uri;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function Lazymint(NFTVoucher calldata voucher, address redeemer, bytes memory signature ,bytes memory data)
        public
        payable
    {
         address signer = _verify(voucher, signature);

        require(hasRole(MINTER_ROLE, signer), "Invalid signature - unknown signer");
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

        _mint(voucher.account, voucher.tokenId, voucher.supply, data);
        tokenIds[voucher.tokenId] = voucher.tokenId;
        setTokenURI(voucher.tokenId, voucher.uri);
        safeTransferFrom(voucher.account, redeemer, voucher.tokenId, voucher.supply, data);
        setApprovalForAll(contractAddress, true);
        address payable receiver = payable(signer);
        receiver.transfer(msg.value);
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
        override(AccessControl,ERC1155)
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