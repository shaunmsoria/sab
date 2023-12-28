import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";
import { SABV1 } from "../typechain-types/contracts/SABV1";
// import { SABV1 } from "../typechain-types/factories/contracts/SABV1__factory";
// import { config } from "../hardhat.config";


describe("SABV1", () => {

    let owner: Signer;
    let sabv1: SABV1;
    
    beforeEach(async () => {
        [owner] = await ethers.getSigners();

        sabv1 = await ethers.getContractFactory("SABV1")
        .then((factory) => factory.deploy())
        .then((contract) => contract.waitForDeployment());

    });


    describe("Deployment", function () {
       it("Sets the owner", async () => {
        expect(await sabv1.owner()).to.equal(await owner.getAddress())
       }) 
    });

});