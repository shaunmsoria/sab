// import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers } from "hardhat";


async function main(){

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