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

    it("Should execute vault.flashloan", async function () {

        async function checkBalance(tokenAddress, walletAddress) {
            const token = await ethers.getContractAt("IERC20", tokenAddress);
            const balance = await token.balanceOf(walletAddress);
            return balance;
        };
          

        async function checkVaultBalance(tokenAddress) {
            const vaultAddress = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";
            return await checkBalance(tokenAddress, vaultAddress);
        };

        const [owner] = await ethers.getSigners();
    
        const SABV2 = await ethers.getContractFactory("SABV2");
        const sabv2 = await SABV2.deploy();
        await sabv2.waitForDeployment();
    
        // Send ETH to contract for gas
        await owner.sendTransaction({
            to: await sabv2.getAddress(),
            value: ethers.parseEther("0.1")
        });
    
        // Test parameters for Ethereum mainnet
        const token0 = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"; // Mainnet USDC
        const token1 = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"; // Mainnet WETH
        const router0 = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; // UniswapV2 Router
        const router1 = "0xE592427A0AEce92De3Edee1F18E0157C05861564"; // UniswapV3 SwapRouter
        const flashAmount = ethers.parseUnits("0.0001", 6); // 0.1 USDC (6 decimals)

        // Check balances first
        const vaultBalance = await checkVaultBalance(token0);
        console.log("Vault USDC balance:", ethers.formatUnits(vaultBalance, 6));

        // Try the simple flash loan first
        await sabv2.testSimpleFlashLoan(token0, flashAmount);
        console.log("Simple flash loan succeeded!");
        
        // Execute trade
        const tx = await sabv2.executeTrade(
            token0,
            token1,
            router0,
            "uniswapV2",
            3000,
            router1,
            "uniswapV3",
            3000,
            flashAmount
        );
        
        const receipt = await tx.wait();
        console.log("Flash loan transaction executed:", receipt.hash);
        expect(receipt.status).to.equal(1);
    });
});