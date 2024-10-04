// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const NFTMarketPlaceModule = buildModule("NFTMarketPlaceModule", (m) => {
 

  const NFTMarketPlace = m.contract("NFTMarketPlace",);

  return { NFTMarketPlace };
});

export default NFTMarketPlaceModule;
