const { ethers } = require("hardhat");
const { expect } = require("chai");



describe("SABV2", function () {
      // Set higher timeout for tests
      this.timeout(60000);

    it("GetBlockNumber", async function () {
        const provider = ethers.provider;
        const blockNumber = await provider.getBlockNumber();
        console.log("Block number: ", blockNumber);
    }); 

    it("Should deploy SABV2", async function () {
        const SABV2 = await ethers.getContractFactory("SABV2");
        const sabv2 = await SABV2.deploy();
        await sabv2.waitForDeployment();
        console.log("SABV2 deployed to:", await sabv2.getAddress());
    });

    it("Should set the right owner", async function () {
        const [owner] = await ethers.getSigners();

        const SABV2 = await ethers.getContractFactory("SABV2");
        const sabv2 = await SABV2.deploy();
        await sabv2.waitForDeployment();
        expect(await sabv2.owner()).to.equal(owner.address);
    });

    it("Should run testSimpleFlashLoan should succeed", async function (){
        const [owner] = await ethers.getSigners();
        const SABV2 = await ethers.getContractFactory("SABV2");
        const sabv2 = await SABV2.deploy();
        await sabv2.waitForDeployment();

        const token0 = "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE"; // Mainnet SHIB

        const flashAmount = ethers.parseUnits("10", 18); // 10 SHIB (18 decimals)
        const result = await sabv2.testSimpleFlashLoan(token0, flashAmount);

        expect(result.value).to.equal(0n);

    });


    it("all events should pass", async function (){
        const [owner] = await ethers.getSigners();
        const SABV2 = await ethers.getContractFactory("SABV2");
        const sabv2 = await SABV2.deploy();
        await sabv2.waitForDeployment();

        const token0 = "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE"; // Mainnet SHIB

        const flashAmount = ethers.parseUnits("10", 18); // 10 SHIB (18 decimals)


        await expect(sabv2.testSimpleFlashLoan(token0, flashAmount))
        .to.emit(sabv2, "ReceiveFlashLoanEvent")
        .withArgs("ReceiveFlashLoanEvent fired");

        await expect(sabv2.testSimpleFlashLoan(token0, flashAmount))
        .to.emit(sabv2, "FlashLoanReceived")
        .withArgs(token0, flashAmount, 0); 

        await expect(sabv2.testSimpleFlashLoan(token0, flashAmount))
        .to.emit(sabv2, "FlashLoanRepaid")
        .withArgs(flashAmount, 0);

        await expect(sabv2.testSimpleFlashLoan(token0, flashAmount))
        .to.emit(sabv2, "ProfitTracked")
        .withArgs(0);
    });

});