import { ethers } from "hardhat";

async function main() {
  // The contract address from your README.md for Lisk Sepolia
  const contractAddress = "0x4E3F362386086D6C9EbbCB4A17FAF52D103831f5";

  // This is the dummy token URI you can replace later.
  const tokenURI = "https://purple-funny-halibut-437.mypinata.cloud/ipfs/bafkreidaosfywumpyezqzcshlhvjihufjffx3omfa6pxzenxjeu3thx2uy";

  // Get the signer to send the transaction
  const [signer] = await ethers.getSigners();

  console.log("Interacting with contract at:", contractAddress);
  console.log("Using signer:", signer.address);

  // Get the contract factory and attach it to the deployed address.
  // The contract name "ERC721" is from your ignition deployment script.
  const erc721 = await ethers.getContractAt("ERC721", contractAddress, signer);

  console.log("Minting a new token...");

  // Note: This assumes your ERC721 contract has a `safeMint(address to, string memory tokenURI)` function.
  // This is a common pattern in OpenZeppelin's ERC721 implementation.
  const tx = await erc721.mint(signer.address, tokenURI);

  console.log("Transaction sent! Hash:", tx.hash);
  await tx.wait();

  console.log("Token minted successfully!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
