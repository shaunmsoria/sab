
require("dotenv").config({ path: '../bot_supervisor/.envrc' });
const hre = require("hardhat");
const { ethers } = require("hardhat");


async function main() {
  const [signer] = await ethers.getSigners();
  
  // const contractAddress = process.env.CONTRACT_ADDRESS;
  const contractAddress = "0x4F7c2894D115AC4b2b6B0544e3471fb10B4dfdF0";
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