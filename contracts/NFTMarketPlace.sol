// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketPlace is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 private nextTokenId;

    struct NFTListing {
        address seller;
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => NFTListing) public nftListings;
    mapping(address => bool) public approvedMinters;
    mapping(address => uint256) public sellerBalances;

    event ListingCreated(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ListingSuccessful(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed tokenId, address indexed seller);
    event BalanceWithdrawn(address indexed seller, uint256 amount);

    constructor() ERC721("NFTMarket", "NFTM") Ownable(msg.sender) {}

    modifier onlyApprovedMinter() {
        require(approvedMinters[msg.sender] || msg.sender == owner(), "Not approved to mint");
        _;
    }

    function setMinterApproval(address minter, bool isApproved) external onlyOwner {
        approvedMinters[minter] = isApproved;
    }

    function createNFT(address to, string memory tokenURI) external onlyApprovedMinter returns (uint256) {
        uint256 newTokenId = nextTokenId++;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        return newTokenId;
    }

    function createListing(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        require(getApproved(tokenId) == address(this), "Market not approved");
        
        nftListings[tokenId] = NFTListing(msg.sender, price, true);
        emit ListingCreated(tokenId, msg.sender, price);
    }

    function cancelListing(uint256 tokenId) external {
        NFTListing storage listing = nftListings[tokenId];
        require(listing.seller == msg.sender, "Not the lister");
        require(listing.isListed, "Not currently listed");

        delete nftListings[tokenId];
        emit ListingCancelled(tokenId, msg.sender);
    }

    function purchaseNFT(uint256 tokenId) external payable nonReentrant {
        NFTListing memory listing = nftListings[tokenId];
        require(listing.isListed, "Not listed for sale");
        require(msg.value >= listing.price, "Insufficient funds sent");
        require(getApproved(tokenId) == address(this), "Market not approved");

        address seller = listing.seller;
        uint256 salePrice = listing.price;

        delete nftListings[tokenId];
        _transfer(seller, msg.sender, tokenId);

        sellerBalances[seller] += salePrice;

        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }

        emit ListingSuccessful(tokenId, seller, msg.sender, salePrice);
    }

    function withdrawBalance() external nonReentrant {
        uint256 balance = sellerBalances[msg.sender];
        require(balance > 0, "No balance to withdraw");

        sellerBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit BalanceWithdrawn(msg.sender, balance);
    }
}