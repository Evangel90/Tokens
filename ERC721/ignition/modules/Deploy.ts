// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://v2.hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployModule = buildModule("ERC721", (m) => {

  const erc721 = m.contract("ERC721", ['ProfilePics', 'PFP']);

  return { erc721 };
});

export default DeployModule;
