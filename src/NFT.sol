// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {

     bytes32 public DOMAIN_SEPARATER;
    mapping(address => uint) public nounces;
    uint256 tokenId;

    constructor() ERC721(unicode"MyNft", "NFT") {}

    function mint() external returns (bool) {
        _mint(msg.sender, tokenId);
        tokenId += 1;
        return true;
    }
    
}