
require("dotenv").config({ path: '../bot_supervisor/.envrc' });
const hre = require("hardhat");
const { ethers } = require("hardhat");


async function main() {
  const [signer] = await ethers.getSigners();
  
  // const contractAddress = process.env.CONTRACT_ADDRESS;
  const contractAddress = "0x9cC87998ba85D81e017E6B7662aC00eE2Ab8fe13";
  console.log(`Sending 0.1 ETH to ${contractAddress} from ${signer.address}`);
  
  const tx = await signer.sendTransaction({
    to: contractAddress,
    value: ethers.parseEther("0.1")
  });
  
  console.log(`Transaction hash: ${tx.hash}`);
  const receipt = await tx.wait();
  console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });