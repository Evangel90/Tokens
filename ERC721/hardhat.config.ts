import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks:{
    sepolia: {
      url: "https://0xrpc.io/sep",
      accounts: [PRIVATE_KEY],
    }
  }
};

export default config;
