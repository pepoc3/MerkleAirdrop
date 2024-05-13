const { MerkleTree }= require('merkletreejs');
const keccak256 = require('keccak256');
let whitelistAddresses =[
    "0x23AE1FC8E4e40274BeB45bb63f773C902EDD7423",
    "0x4BE2427c676b1DCb266b7f91245Ac82672ce46Fd",
    "0x4BE2427c676b1DCb266b7f91245Ac82672ce46F1",
    "0x4BE2427c676b1DCb266b7f91245Ac82672ce46F2"

]  //白名单

const leafNodes=whitelistAddresses.map(addr =>keccak256(addr));  //叶子节点
const merkleTree = new MerkleTree(leafNodes, keccak256,{ sortPairs: true }); //构建树

const rootHash = merkleTree.getHexRoot();  //root哈希
console.log('Whitelist root hash: ', rootHash); 

const claimingAddress = leafNodes[0]; //要验证的地址
const hexProof = merkleTree.getHexProof(claimingAddress);  
// console.log(leafNodes[0]);
console.log(hexProof);
// console.log('Whitelist Adams Tree\n', merkleTree.toString());