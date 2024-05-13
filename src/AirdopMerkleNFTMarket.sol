// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NFT.sol";
import "./Token.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract AirdopMerkleNFTMarket {
    IERC721 public nftContract;
    ERC20Permit public tokenContract;
    struct  Listing {
        address seller;
        uint256 price;
    }
    bytes32 public immutable merkleRoot; //默克尔树根节点
    mapping(uint256 => uint256) prices;
    mapping(uint256 => address) sellers;
    mapping(uint256 => Listing) public listings;
    mapping(address => uint256) public userBalances;
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event Sold(address seller, address buyer, uint256 price);
    event Listed(address seller, uint256 price);
    error DelegatecallFailed(); 

    constructor(address _nftContract, address _tokenContract, bytes32 merkleRoot_) {
        nftContract = IERC721(_nftContract);
        tokenContract = ERC20Permit(_tokenContract);
        merkleRoot = merkleRoot_;
    }

    function getTokenPrice(uint256 _tokenId)  public view returns (uint256) {
        Listing memory listing = listings[_tokenId];
        return listing.price;
    }

    function list(uint256 _tokenId, uint256 _price) external {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_price > 0, "Price must be greater than zero");

        listings[_tokenId] = Listing(msg.sender, _price);
        emit NFTListed(_tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _tokenId) internal {
        Listing memory listing = listings[_tokenId];
        require(listing.seller != address(0), "NFT is not listed for sale");

        uint256 price = listing.price;
        address seller = listing.seller;

        require(tokenContract.transferFrom(msg.sender, seller, price), "Token transfer failed");
        nftContract.safeTransferFrom(seller, msg.sender, _tokenId);

        delete listings[_tokenId];
        emit NFTSold(_tokenId, msg.sender, price);
    }

    
    //白名单用户买NFT
    function WhiteBuyNFT(uint256 _tokenId) internal {
        Listing memory listing = listings[_tokenId];
        require(listing.seller != address(0), "NFT is not listed for sale");

        uint256 price = listing.price / 2;
        address seller = listing.seller;

        require(tokenContract.transferFrom(msg.sender, seller, price), "Token transfer failed");
        nftContract.safeTransferFrom(seller, msg.sender, _tokenId);

        delete listings[_tokenId];
        emit NFTSold(_tokenId, msg.sender, price);
    }
    function permitPrePay(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) public {
        tokenContract.permit(owner,spender,value,deadline,v,r,s);
    }

    function claimNFT(bytes32[] calldata merkleProof, uint256 _tokenId) public {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // permitPrePay(owner,spender,value,deadline,v,r,s);
        WhiteBuyNFT(_tokenId);

    }

    
    function multiDelegatecall(bytes[] memory data)
        external
        payable
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        for (uint256 i; i < data.length; i++) {
            (bool ok, bytes memory res) = address(this).delegatecall(data[i]);
            if (!ok) {
                revert DelegatecallFailed();
            }
            results[i] = res;
        }
    }

}