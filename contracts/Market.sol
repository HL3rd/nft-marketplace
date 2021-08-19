// contracts/Market.sol
// Contract based on:
// https://github.com/ourzora/core/blob/master/contracts/Market.sol
// https://gist.github.com/dabit3/92a572060d62c49707dd0b80378a11ab
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract Market is ReentrancyGuard {
  using Counters for Counters.Counter;

  /**
   * Globals
   */
  
  // Incrementer for items on our Market
  Counters.Counter private _itemIds;

  // Counts total items sold on our Market
  Counters.Counter private _itemsSold;

  // Deployment address
  address payable owner;

  // Default price for a MarketItem
  uint256 listingPrice = 0.021 ether;

  constructor() {
    owner = payable(msg.sender);
  }

  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;
  }

  // Acts like a dicitonary to easily map itemId to MarketItem object
  mapping(uint256 => MarketItem) private idToMarketItem;

  event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
  );

  /**
   * Returns the listing price we set on our contract
   */
  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }
  
  /**
   * Places an item for sale on the marketplace
   * Emits MarketItemCreated event on completion
   * @param nftContract contract address where the NFT was minted
   * @param tokenId id of the token (created by Counter in NFT.sol)
   * @param price price of the MarketItem
   */
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable nonReentrant {
    require(price > 0, "Price must be at least 1 wei");
    require(msg.value == listingPrice, "Price must be equal to listing price");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();

    // Set the mapping of itemId to the newly initialized MarketItem
    // seller = payable(msg.sender)
    // owner = payable(address(0)) (address(0) means no owner)
    idToMarketItem[itemId] =  MarketItem(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      false
    );

    // Transfer NFT ownership/custody from creator to our Market address
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    // Emit the MarketItemCreated event
    emit MarketItemCreated(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      false
    );
  }

  /**
   * Sells the MarketItem
   * Handles transference of the item ownership and funds
   * @param nftContract the address of the NFT contract
   * @param itemId the id of our MarketItem, used to fetch the full MarketItem object
   */
  function createMarketSale(address nftContract, uint256 itemId)
      public
      payable
      nonReentrant
  {
    // Fetch MarketItem using itemId and the mapping
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");

    // Send the wei to the seller and transfer NFT from Market to buyer
    idToMarketItem[itemId].seller.transfer(msg.value);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

    // Update the MarketItem properties
    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].sold = true;
    
    // Increment total items sold and transfer listing fee to our Market
    _itemsSold.increment();
    payable(owner).transfer(listingPrice);
  }

  /**
   * Returns the MarketItem[] that are not sold
   */
  function fetchMarketItems()
      public
      view
      returns (MarketItem[] memory)
  {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId =  i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /**
   * Returns the MarketItem[] that belong to calling user (msg.sender)
   */
  function fetchMyNFTs()
      public
      view
      returns (MarketItem[] memory)
  {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId =  i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /**
   * Returns the MarketItem[] created by calling user (msg.sender)
   */
  function fetchItemsCreated()
      public
      view
      returns (MarketItem[] memory)
  {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
}