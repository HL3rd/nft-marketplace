/* pages/MainPage.tsx */
import { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import axios from 'axios';
import Web3Modal from "web3modal";

require('dotenv').config();
const alchemyKey = process.env.ALCHEMY_KEY;
const { createAlchemyWeb3 } = require('@alch/alchemy-web3');
const web3 = createAlchemyWeb3(alchemyKey);

// const contractAddress = "0x4C4a07F737Bf57F6632B6CAB089B78f62385aCaE"; // Alchemy web3
import { nftAddress, marketAddress } from '../config'; // Nader web3

// const contractABI = require('../contract-abi.json'); // Alchemy web3
import NFT from '../artifacts/contracts/NFT.sol/NFT.json'; // Nader web3
import Market from '../artifacts/contracts/Market.sol/Market.json'; // Nader web3

const MainPage = () => {

  const [nfts, setNfts] = useState([])
  const [loadingState, setLoadingState] = useState('not-loaded');

  useEffect(() => {
    loadNFTs()
  }, []);

  // Function to fetch and disply the NFTs on the market
  async function loadNFTs() {
    // Load the smart contracts
    const tokenContract = await new web3.eth.Contract(NFT.abi, nftAddress);
    const marketContract = await new web3.eth.Contract(Market.abi, marketAddress); 
    
    const data = await marketContract.fetchMarketItems()
    
    // format items from contract and fetch their token metadata
    const items = await Promise.all(data.map(async i => {
      const tokenUri = await tokenContract.tokenURI(i.tokenId);
      const meta = await axios.get(tokenUri);
      let price = ethers.utils.formatUnits(i.price.toString(), 'ether')
      let item = {
        price,
        tokenId: i.tokenId.toNumber(),
        seller: i.seller,
        owner: i.owner,
        image: meta.data.image,
        name: meta.data.name,
        description: meta.data.description,
      }
      return item
    }))
    setNfts(items)
    setLoadingState('loaded') 
  }

  // Function to buy an NFT on our market
  async function buyNFT(nft) {
    /* needs the user to sign the transaction, so will use Web3Provider and sign it */
    const web3Modal = new Web3Modal() // Nader web3
    const connection = await web3Modal.connect() // Nader web3
    const provider = new ethers.providers.Web3Provider(connection);
    const signer = provider.getSigner()
    const contract = new web3.eth.Contract(Market.abi, signer);

    /* user will be prompted to pay the asking proces to complete the transaction */
    const price = ethers.utils.parseUnits(nft.price.toString(), 'ether')   
    const transaction = await contract.createMarketSale(nftAddress, nft.tokenId, {
      value: price
    })
    await transaction.wait()
    loadNFTs()
  }

  if (loadingState === 'loaded' && !nfts.length) return (<h1 className="px-20 py-10 text-3xl">No items in marketplace</h1>)
  
  return (
    <div className="flex justify-center">
      <div className="px-4" style={{ maxWidth: '1600px' }}>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4">
          {
            nfts.map((nft, i) => (
              <div key={i} className="border shadow rounded-xl overflow-hidden">
                <img src={nft.image} />
                <div className="p-4">
                  <p style={{ height: '64px' }} className="text-2xl font-semibold">{nft.name}</p>
                  <div style={{ height: '70px', overflow: 'hidden' }}>
                    <p className="text-gray-400">{nft.description}</p>
                  </div>
                </div>
                <div className="p-4 bg-black">
                  <p className="text-2xl mb-4 font-bold text-white">{nft.price} ETH</p>
                  <button className="w-full bg-pink-500 text-white font-bold py-2 px-12 rounded" onClick={() => buyNFT(nft)}>Buy</button>
                </div>
              </div>
            ))
          }
        </div>
      </div>
    </div>
  )
}

export default MainPage;