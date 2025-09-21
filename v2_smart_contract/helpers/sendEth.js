
require("dotenv").config({ path: '../bot_supervisor/.envrc' });
const hre = require("hardhat");
const { ethers } = require("hardhat");


async function main() {
  // const [signer] = await ethers.getSigners();

  const privateKey = process.env.PRIVATE_KEY;

  console.log("mx1 privateKey", privateKey);
  const provider = hre.ethers.provider;
  const signer = new hre.ethers.Wallet(privateKey, provider);
  
  // const contractAddress = process.env.CONTRACT_ADDRESS;
  const contractAddress = "0xE38aF3FDa379401445FFD7b9cD57D0D33d03790E";
  console.log(`Sending 0.005 ETH to ${contractAddress} from ${signer.address}`);
  
  const tx = await signer.sendTransaction({
    to: contractAddress,
    value: ethers.parseEther("0.005")
  });
  
  console.log(`Transaction hash: ${tx.hash}`);
  const receipt = await tx.wait();
  console.log(`receipt ${JSON.stringify(receipt)}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });