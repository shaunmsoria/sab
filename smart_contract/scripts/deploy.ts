// import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers } from "hardhat";
import { config } from "dotenv";
import { Signer } from "ethers";

config();


async function main(){

    const ownerAddress = process.env.ACCOUNT_NUMBER;
    
    // const SABV1 = await ethers.deployContract(
    //     "SABV1",
    //     [
    //         "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
    //         "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F"
    //     ]
    // )
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