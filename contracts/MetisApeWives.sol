// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract MetisApeWives is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant MAX_WHITELIST_MINT = 15;
    uint256 public constant PUBLIC_SALE_PRICE = .15 ether;
    uint256 public constant WHITELIST_SALE_PRICE = .1 ether;

    string private baseTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale
    //2 days later toggle reveal
    bool public publicSale;
    bool public whiteListSale;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("Metis ApeWives", "mDAW") {}

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Metis ApeWives :: Cannot be called by a contract"
        );
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(publicSale, "Metis ApeWives :: Not Yet Active.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Metis ApeWives :: Beyond Max Supply"
        );
        require(
            (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            "Metis ApeWives :: Already minted 10 times!"
        );
        require(
            msg.value >= (PUBLIC_SALE_PRICE * _quantity),
            "Metis ApeWives :: Not enough Metis"
        );

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    //function seeIt(uint256 _num) public view {
    // console.log(_num);
    //bytes32 sender = keccak256(abi.encodePacked(msg.sender));
    // console.log(sender);

    //}

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity)
        external
        payable
        callerIsUser
    {
        require(whiteListSale, "Metis ApeWives :: Minting is on Pause");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Metis ApeWives :: Cannot mint more than the max supply"
        );
        require(
            (totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT,
            "Metis ApeWives :: Cannot mint more than 15 ApeWives!"
        );
        require(
            msg.value >= (WHITELIST_SALE_PRICE * _quantity),
            "Metis ApeWives :: Payment is below the price"
        );
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender)); //kanei to address tou caller se hexa
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender), //kanei verify to path tou leaf, to root kai to address tou caller se hexa
            "Metis ApeWives :: You are not whitelisted"
        );

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // function isWhiteListed(bytes32[] memory _merkleProof) external view  callerIsUser returns(bool _response) {
    //     bytes32 sender = keccak256(abi.encodePacked(msg.sender));
    //     require(
    //         MerkleProof.verify(_merkleProof, merkleRoot, sender),
    //         "Metis ApeWives :: You are not whitelisted"
    //     );
    //     return true;

    // }

    function teamMint() external onlyOwner {
        require(!teamMinted, "Metis ApeWives :: Team minted");
        teamMinted = true;
        _safeMint(msg.sender, 500);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function showCaller() external view returns (address ad) {
        return msg.sender;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 trueId = tokenId + 1;

        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns (uint256[] memory) {
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for (uint256 index = 0; index < numberOfOwnedNFT; index++) {
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function toggleWhiteListSale() external onlyOwner {
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function getContractBalance()
        external
        view
        onlyOwner
        returns (uint256 amount)
    {
        return address(this).balance;
    }

    // function isValid(bytes32[] memory proof,bytes32 leaf) public returns(bool) view{
    //     MerkleProof.verify(proof,merkleRoot,leaf)
    // }

    function withdraw() external onlyOwner {
        //50% to artist wallet
        uint256 withdrawAmount_50 = (address(this).balance * 50) / 100;
        //35% to dev
        uint256 withdrawAmount_35 = (address(this).balance * 35) / 100;
        //15% to dao
        uint256 withdrawAmount_15 = (address(this).balance * 15) / 100;
        payable(0xe7F40c69C5d95d05E4b5De91eD4feb54a685f635).transfer(
            withdrawAmount_50
        );
        payable(0x5bAa05635EDADBa555DAC7A5F52C9d09b4E12EA4).transfer(
            withdrawAmount_35
        );
        payable(0x067E96F53A04Da7fB19f353237941dA95A2398df).transfer(
            withdrawAmount_15
        );
        payable(msg.sender).transfer(address(this).balance);
    }
}

// [
//   "0xa7c4a66ec9b11ff024c8f3107b260b90aceae4b355a465851cde00c14a8e8feb",
//   "0x527a1328d6e0a835e7fa9b1fb0eec722203161d38d67bd4b83cb1d12bd1d35a3",
//   "0xe7e9f7530c63ac2692dc90fc4b2f69575c802d061626c26d68b7440b02102add",
//   "0xf402dc88c2d801aa0ec42fbd827ebb65151f47307632f6689152ad50f6dcd318",
//   "0xa0709c8a55e4fe670a4b04f393048228407f955fe266d24f3e0aa3d7fc168f34",
//   "0xef3051ae08c903dd3f36942ed87953b041205cceda40c941bb836b05160e8055",
//   "0x9f86faf559e131c380ec94d385ac2860b840905354301523d446b39ebb830269"
// ]

// [
//   "0x2879e45ed4563368cf0b30fb6e6b24df6470ba85d1ceff695541e38a1573e981",
//   "0x7f91e9f0a94da5335f769acd86c496cd9004bc0104b9161a3c6c87f3a57caf40",
//   "0xab070f729ed4905e4e45b74812777a8d0a80a250c257d3b60a52c34b6ed9dca1",
//   "0xe9c551f0135f6623b31436072a5c21d9c30550c5ce606c66c67930988f10b309",
//   "0x416b2c97c92ac82caa2b983b7d138d8fcbb0cecd5d483001617e0f57f6bdfe4e",
//   "0xd7ea2d5fe34e9120c6c83612bf0596c58d3423d26d584a499268337ae765ac64",
//   "0x0b216cdc7febacfe44985c4d6102aa4e67341c8c50c715ab920229ebdedc21b6",
//   "0xd7acc32df28b11b6c36c6bab4c59ece10da794ca27994b11eb9b740c04a5cbb8",
//   "0xe2425450aa2168ddd4ef2d0fc9b36f5399d7b1395cef9ed4e32959b9c4cadd7f",
//   "0xcf51023e5f9f51b99304c05e58797c86c5b6a8afd3bc29d432789ad9a1971d3d",
//   "0x7ca7da75ccb04304d6afd82329c0aef5bcefe6d62e112087982e92327f2dcf32"
// ]
