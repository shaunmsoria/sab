// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat")
const { ethers } = require("hardhat")

const config = require("../config.json")




async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("sx1 deployer", deployer);
  
  const SABV2 = await hre.ethers.deployContract(
    "SABV2",
    [],
    {
      signer: deployer,
      maxFeePerGas: 10000000000,
    }
  )

  await SABV2.waitForDeployment()


  console.log(`SABV2 contract deployed to ${await SABV2.getAddress()}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});