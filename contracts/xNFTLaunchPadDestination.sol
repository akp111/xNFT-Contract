// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// import {CallParams, XCallArgs} from "@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol";

contract NFTContract is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tokenCount;

    address public  owner;
    address newOwner;
    uint256 public  price;
    uint256 contractBalance;
    string public  _tokenURI;
    string _tokenURIBulk;

    uint256 public constant MAX_CAP = 200;

    event OwnershipTransferred(address);
    event OwnershipClaimed(address);
    event Minted(uint256, address);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can invoke this function");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _owner,
        string memory tokenURILocal,
        uint256 _price
    ) ERC721(name, symbol) {
        owner = _owner;
        _tokenURI = tokenURILocal;
        price = _price;
    }

    function grantOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be a zero address");
        newOwner = _newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function claimOwnerShip() external {
        require(
            msg.sender == newOwner,
            "Only new owner can call this function"
        );
        owner = msg.sender;

        emit OwnershipClaimed(msg.sender);
    }

    function setNFTPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setTokenURIForBulkMint(string memory _tokenURIBulkMint)
        external
        onlyOwner
    {
        _tokenURIBulk = _tokenURIBulkMint;
    }

    //Anyone can mint a single NFT from this contract - the tokenURI will be set by the owner
    function mintSingleNFT(address to) external payable {
        require(msg.value >= price, "You need to pay to mint the NFT");

        tokenCount.increment();
        uint256 tokenId = tokenCount.current();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        emit Minted(tokenId, to);

        contractBalance += msg.value;
    }

    //Only owner can mint bulk NFTs and this is for use cases like print game assets and put it up for sale, etc.
    function mintBulkNFTs(address[] memory to) external onlyOwner {
        require(
            bytes(_tokenURIBulk).length != 0,
            "Token URI cannot be null for bulk mint"
        );

        for (uint256 i = 0; i < to.length; i++) {
            require(
                MAX_CAP >= tokenCount.current(),
                "Cannot mint more than 200 tokens"
            );

            tokenCount.increment();
            uint256 tokenId = tokenCount.current();

            _safeMint(to[i], tokenId);
            _setTokenURI(tokenId, _tokenURIBulk);

            emit Minted(tokenId, to[i]);
        }
    }

    function withdrawFunds() external onlyOwner {
        (bool sent, ) = address(msg.sender).call{value: contractBalance}("");

        require(sent, "Ether not sent");
    }
}

//Factory Contract
contract xNFTLaunchPadDestination {
    // struct NFTDetails {
    //     string name;
    //     string symbol;
    //     string tokenURI;
    //     uint256 price;
    // }

    // mapping(uint256 => NFTDetails) public nftMapping;

    // function deploy(
    //     string memory name,
    //     string memory symbol,
    //     string memory tokenURI,
    //     uint256 price
    // ) external {
    //     NFTDetails memory newEntry;
    //     newEntry.name = name;
    //     newEntry.symbol = symbol;
    //     newEntry.tokenURI = tokenURI;
    //     newEntry.price = price;

    //     nftMapping[++index] = newEntry;
    // }

    struct _contract {
        uint256 id;
        address owner;
        address contractAddress;
    }

    _contract[] Contracts;
    mapping(address => address[]) addressContractMap;

    event LaunchNFTContract(address indexed, address indexed);

    constructor() {}

    function deploy(
        string memory name,
        string memory symbol,
        string memory tokenURI,
        uint price,
        address owner
    ) external {
        NFTContract nftContract = new NFTContract(
            name,
            symbol,
            owner,
            tokenURI,
            price
        );
        Contracts.push();

        uint256 index = Contracts.length - 1;
        Contracts[index].owner = owner;
        Contracts[index].id = index;
        Contracts[index].contractAddress = address(nftContract);

        addressContractMap[owner].push(address(nftContract));

        emit LaunchNFTContract(address(nftContract), owner);
    }

    //Returns the NFT contract addresses for a particular owner
    function getContract() external view returns (address[] memory) {
        return (addressContractMap[msg.sender]);
    }

    //Get all the contract addresses of the various NFT Contracts
    function getAllContracts() external view returns (_contract[] memory) {
        return Contracts;
    }
}
