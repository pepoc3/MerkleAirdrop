// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {AirdopMerkleNFTMarket} from "../src/AirdopMerkleNFTMarket.sol";
import {NFT} from "../src/NFT.sol";
import {Token} from "../src/Token.sol";
import {Test, console} from "forge-std/Test.sol";

contract AirdopMerkleNFTMarketTest is Test {
    AirdopMerkleNFTMarket public airdopMerkleNFTMarket;
    NFT public nft;
    Token public token;
    address alice = makeAddr("Alice");
    address bob = 0x23AE1FC8E4e40274BeB45bb63f773C902EDD7423;  //白名单用户
    bytes32 roothash = 0x59f9090bc24fe9d10bc09817e39bb1f66171b3bdad108aaf1e2454d65fd658c6;//默克尔树头结点哈希
    // bytes32[]  merkleProof= [0x040f8465f0461e1a1a95047a55587a2b1274c0d03725abbb6405d51fdf63e2ad, 0x9fafe40fd0c057bdbbb76db790ba783229743e5e5d188208aaf81d0281d1d34a];
    

    // bytes32[] merkleProof;

    // constructor() {
    // merkleProof = new bytes32 ; // 指定数组长度为2
    // merkleProof[0] = 0x040f8465f0461e1a1a95047a55587a2b1274c0d03725abbb6405d51fdf63e2ad;
    // merkleProof[1] = 0x9fafe40fd0c057bdbbb76db790ba783229743e5e5d188208aaf81d0281d1d34a;
    // }
    function setUp() public {
        
        nft = new NFT();
        token = new Token();
        airdopMerkleNFTMarket = new AirdopMerkleNFTMarket(nft, token, roothash);
        vm.prank(alice);
        nft.mint();
        vm.prank(address(this));
        token.transfer(bob, 100);
        
    }

    function test_MerkleProofVerify() public {
        // bytes32[] storage merkleProof = new bytes32;
        // merkleProof[0] = 0x040f8465f0461e1a1a95047a55587a2b1274c0d03725abbb6405d51fdf63e2ad;
        // merkleProof[1] = 0x9fafe40fd0c057bdbbb76db790ba783229743e5e5d188208aaf81d0281d1d34a;
        bytes32[]  calldata merkleProof= [0x040f8465f0461e1a1a95047a55587a2b1274c0d03725abbb6405d51fdf63e2ad, 0x9fafe40fd0c057bdbbb76db790ba783229743e5e5d188208aaf81d0281d1d34a];
        vm.prank(alice);
        airdopMerkleNFTMarket.list(0, 1);
        vm.prank(bob);
        airdopMerkleNFTMarket.claimNFT(merkleProof, 0);  //tokenId为0

    }

    function test_multicall() public {
        bytes32[]  calldata merkleProof= [0x040f8465f0461e1a1a95047a55587a2b1274c0d03725abbb6405d51fdf63e2ad, 0x9fafe40fd0c057bdbbb76db790ba783229743e5e5d188208aaf81d0281d1d34a];
        vm.prank(alice);
        airdopMerkleNFTMarket.list(0, 10);
        vm.prank(bob);
        airdopMerkleNFTMarket.claimNFT(merkleProof, 0);  //tokenId为0

        //生成签名
        bytes32 digest = keccak256(
            abi.encodePacked(
                hex"1901",
                Token.DOMAIN_SEPARATER(),
                keccak256(
                    abi.encode(
                        keccak256(
                            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                        ),
                        bob,
                        address(airdopMerkleNFTMarket),
                        5,
                        0,
                        1 days
                    )
                )
            )
        );
        bytes = 2463e392e4fbb7fda204e57ca4433f261fc2ae4d16850dc3258c3decb090f058;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPrivateKey, digest);

        bytes32 memory permitPrePay = abi.encodeWithSelector(airdopMerkleNFTMarket.permitPrePay.selector, alice, address(airdopMerkleNFTMarket), 5, v,r,s); 
        bytes32 memory claimNFT = abi.encodeWithSelector(airdopMerkleNFTMarket.claimNFT.selector, merkleProof, 0);
        bytes[] memory data = new bytes[];
        data[0]= permitPrePay;
        data[1] = claimNFT;
        multiDelegatecall(data);
    }

    
}

