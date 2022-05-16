// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./signtureEIP712/signtureERC721.sol";
import "../../royalties/impl/RoyaltiesV2impl.sol";
import "../../royalties/LibRoyality.sol";
import "../../royalties/LibRoyaltiesV2.sol";

contract TokenERC721LazyMint is ERC721URIStorage, ERC721Burnable, RoyaltiesV2Impl, Ownable, signtureERC721, AccessControl {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address public contractAddress;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 lastTokenID;
    string contracturi;


    mapping(uint256 => address) public minters;
    mapping(uint256 => uint256) public getTokenIDs;
    mapping(address => uint256) public tokenIds;


    modifier isOwnerTokenId(uint256 _tokenId) {
        require(ownerOf(_tokenId) == address(msg.sender) , "you should be owner this token id");
        _;
    }

    constructor (string memory _name, string memory _symbol, address minter, address contractAddr, string memory _contracturi)
     ERC721(_name, _symbol)
    {
       _setupRole(MINTER_ROLE, minter);
       contractAddress = contractAddr;
       contracturi = _contracturi;
    }

    function contractURI() public view returns (string memory) {
        return contracturi;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contracturi = _contractURI;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function lazyMint(address redeemer, NFTVoucher calldata voucher, bytes memory signature) public payable {
        address signer = _verify(voucher, signature);

        require(hasRole(MINTER_ROLE, signer), "Invalid signature - unknown signer");
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
        _transfer(signer, redeemer, voucher.tokenId);
        setApprovalForAll(contractAddress, true);
        address payable receiver = payable(signer);
        receiver.transfer(msg.value);
        minters[voucher.tokenId] = signer;
        getTokenIDs[voucher.tokenId] = voucher.tokenId;
    }

    function UpdateTokenURI(uint256 _tokenId, string memory _uri) public isOwnerTokenId(_tokenId) {
        _setTokenURI(_tokenId, _uri);
    }

    function getLastTokenID() public view returns(uint256){
        return lastTokenID;
    }

    // configure royalties for Rariable
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


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl,ERC721)
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
