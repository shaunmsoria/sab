import { HardhatRuntimeEnvironment } from "hardhat/types"

async function main(hre: HardhatRuntimeEnvironment){
    const SABV1 = await hre.ethers.deployContract(
        "SABV1"
        // to do
    )
}