// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
require("dotenv").config();
const hre = require("hardhat")
const { ethers } = require("hardhat")

const config = require("../config.json")




async function main() {
  const privateKey = process.env.PRIVATE_KEY;

  // console.log("mx1 privateKey", privateKey);
  const provider = hre.ethers.provider;
  const deployer = new hre.ethers.Wallet(privateKey, provider);

  // const [deployer] = await ethers.getSigners();
  console.log("sx1 deployer", deployer);

  const SabLibrary = await hre.ethers.deployContract(
    "SabLibrary",
    [],
    {
      signer: deployer,
      maxFeePerGas: 30000000000
    }
  )

  await SabLibrary.waitForDeployment()

  const sabLibraryAddress = await SabLibrary.getAddress();

  console.log(`SABV2SabLibrary contract deployed to ${sabLibraryAddress}`)

  const hardhatConfig = require("../hardhat.config");
  hardhatConfig.libraries = {
    "contracts/SabLibrary.sol": {
      "SabLibrary": sabLibraryAddress
    }
  };

  // Force recompilation to use the library address
  await hre.run("compile", { force: true });

  
  const SABV2 = await hre.ethers.deployContract(
    "SABV2",
    [],
    {
      signer: deployer,
      maxFeePerGas: 30000000000,
      // libraries: {
      //   SabLibrary: sabLibraryAddress  // Link the library here
      // }
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