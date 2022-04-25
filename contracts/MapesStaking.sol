// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import "./MetisApeWives.sol";
// import "./MapesRewards.sol";

// contract MapesStaking is Ownable, IERC721Receiver {
//     uint256 public totalStaked;

//     //struct that stores a staker's token, owner,earning values
//     struct Stake {
//         uint24 tokenId;
//         uint48 timestamp;
//         address owner;
//     }

//     event NFTStaked(address owner, uint256 tokenId, uint256 value);
//     event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
//     event Claimed(address owner, uint256 value);

//     //point to the nft collection and the erc20 reward token contract
//     MetisApeWives nft;
//     MapesRewards token;

//     //referenced tokenid to stake ... this means that an int representing an nft tokenid will be pointing to a struct instance which will store the id,the timestamp it was staked and the amount of tokens it has generated
//     mapping(uint256 => Stake) public vault;

//     constructor(MetisApeWives _nft, MapesRewards _token) {
//         nft = _nft;
//         token = _token;
//     }

//     function stake(uint256[] calldata tokenIds) external {
//         uint256 tokenId;
//         totalStaked += tokenIds.length;
//         for (uint256 i = 0; i < tokenIds.length; i++) {
//             tokenId = tokenIds[i];
//             require(nft.ownerOf(tokenId) == msg.sender, "not your token");
//             require(vault[tokenId].tokenId == 0, "already staked");
//             nft.transferFrom(msg.sender, address(this), tokenId);

//             emit NFTStaked(msg.sender, tokenId, block.timestamp);

//             vault[tokenId] = Stake({
//                 owner: msg.sender,
//                 tokenId: uint24(tokenId),
//                 timestamp: uint48(block.timestamp)
//             });
//         }
//     }

//     function _unstakeMany(address account, uint256[] calldata tokenIds)
//         internal
//     {
//         uint256 tokenId;
//         totalStaked -= tokenIds.length;

//         for (uint256 i = 0; i < tokenIds.length; i++) {
//             tokenId = tokenIds[i];
//             Stake memory staked = vault[tokenId];
//             require(staked.owner == msg.sender, "not an owner");

//             delete vault[tokenId];
//             emit NFTUnstaked(account, tokenId, block.timestamp);
//             nft.transferFrom(address(this), account, tokenId);
//         }
//     }

//     function claim(uint256[] calldata tokenIds) external {
//         _claim(msg.sender, tokenIds, false);
//     }

//     function claimForAddress(address account, uint256[] calldata tokenIds)
//         external
//     {
//         _claim(account, tokenIds, false);
//     }

//     function unstake(uint256[] calldata tokenIds) external {
//         _claim(msg.sender, tokenIds, true);
//     }

//     function claim(
//         address account,
//         uint256[] calldata tokenIds,
//         bool _unstake
//     ) internal {
//         uint256 tokenId;
//         uint256 earned = 0;

//         for (uint256 i = 0; i < tokenIds.length; i++) {
//             tokenId = tokenIds[i];
//             Stake memory staked = vault[tokenId];
//             require(staked.owner == account, "not an owner");
//             uint256 stakedAt = staked.timestamp;
//             earned += (10000 ether * (block.timestamp - stakedAt)) / 1 days;
//             vault[tokenId] = Stake({
//                 owner: account,
//                 tokenId: uint24(tokenId),
//                 timestamp: uint48(block.timestamp)
//             });
//         }
//         if (earned > 0) {
//             earned = earned / 10000;
//             token.mint(account, earned);
//         }
//         if (_unstake) {
//             _unstakeMany(account, tokenIds);
//         }
//         emit Claimed(account, earned);
//     }

//     function earningInfo(uint256[] calldata tokenIds)
//         external
//         view
//         returns (uint256[2] memory info)
//     {
//         uint256 tokenId;
//         uint256 earned = 0;

//         Stake memory staked = vault[tokenId];
//         uint256 stakedAt = staked.timestamp;
//         earned += (10000 ether * (block.timestamp - stakedAt)) / 1 days;
//         return [earned];
//     }

//     function balanceOf(address account) public view returns (uint256) {
//         uint256 balance = 0;
//         uint256 supply = nft.totalSupply();
//         for (uint256 i = 0; i <= supply; i++) {
//             if (vault[i].owner == account) {
//                 balance += 1;
//             }
//         }

//         return balance;
//     }

//     function tokensOfOwner(address account)
//         public
//         view
//         returns (uint256[] memory ownerTokens)
//     {
//         uint256 supply = nft.totalSupply();
//         uint256[] memory tmp = new uint256[](supply);

//         uint256 index = 0;
//         for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
//             if (vault[tokenId].owner == account) {
//                 tmp[index] = vault[tokenId].tokenId;
//                 index += 1;
//             }
//         }

//         uint256[] memory tokens = new uint256[](index);
//         for (uint256 i = 0; i < index; i++) {
//             tokens[i] = tmp[i];
//         }

//         return tokens;
//     }

//     function onERC721Received(
//         address,
//         address from,
//         uint256,
//         bytes calldata
//     ) external pure override returns (bytes4) {
//         require(from == address(0x0), "Cannot send NFTs to vault directory");
//         return IERC721Receiver.onERC721Received.selector;
//     }
// }
