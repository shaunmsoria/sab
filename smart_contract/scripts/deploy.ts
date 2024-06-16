// import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers } from "hardhat";
import { config } from "dotenv";
import { Signer } from "ethers";

config();


async function main(){

    // const ownerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const ownerAddress = process.env.ACCOUNT_NUMBER;

    // const impersonatedSigner : Signer = await ethers.getImpersonatedSigner(ownerAddress);

// Get the contract factory with the specified signer
//   const SABV1Factory = await ethers.getContractFactory("SABV1", impersonatedSigner);

  // Deploy the contract
//   const SABV1 = await SABV1Factory.deploy();

  // Wait for the deployment to be confirmed
//   await SABV1.deployed();

    const SABV1 = await ethers.deployContract(
        "SABV1",
        []
    )

    await SABV1.waitForDeployment()

    console.log(`SABV1 contract deployed to ${await SABV1.getAddress()}`)

}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});