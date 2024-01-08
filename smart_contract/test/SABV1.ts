import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";
import { SABV1 } from "../typechain-types/contracts/SABV1";
import config from "../tsconfig.json";
import { provider, uFactory, uRouter, sFactory, sRouter, accountNumber  } from "../helpers/initialisation";


describe("SABV1", () => {

    type ERC20Address = string;
    type Factory_Router = {
        V2_ROUTER_02_ADDRESS: ERC20Address,
        FACTORY_ADDRESS: ERC20Address
    }

    let owner: Signer;
    let sabv1: SABV1;
    let uniswap: Factory_Router;
    let sushiswap: Factory_Router;
    let token0: ERC20Address;
    let token1: ERC20Address;
    let account: string;

    
    beforeEach(async () => {
        [owner] = await ethers.getSigners();

        sabv1 = await ethers.getContractFactory("SABV1")
        .then((factory) => factory.deploy())
        .then((contract) => contract.waitForDeployment());

        uniswap = config.UNISWAP;
        sushiswap = config.SUSHISWAP;

        token0 = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
        token1 = "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE";

        account = accountNumber;

    });


    describe("Deployment", function () {
       it("Sets the owner", async () => {
        expect(await sabv1.owner()).to.equal(await owner.getAddress())
       }) 
    });

    describe("executeTrade", function () {
       it("Uniswap to Sushiswap", async () => {
        // console.log("sx1 provider", provider);
        console.log("sx1 uRouter", uRouter);
        console.log("sx1 sRouter", sRouter);
        console.log("sx1 token1", token0);
        console.log("sx1 token2", token1);

        // uFactory, uRouter, sFactory, sRouter

        
        let result;
        result = await sabv1.executeTrade(
            token0, token1, uRouter, sRouter, 1);
        
        // let result;
        // result = await sabv1.executeTrade(
        //     token0, token1, uniswap.V2_ROUTER_02_ADDRESS, sushiswap.V2_ROUTER_02_ADDRESS, 1);

            // let result;
        // result = await sabv1.executeTrade(
        //     token1, token0, sushiswap.V2_ROUTER_02_ADDRESS, uniswap.V2_ROUTER_02_ADDRESS, 1);

        console.log("sx1 value of accouny", account);

        console.log("sx1 value of result", result);

        expect(result.from).to.equal(account);
       }) 
    });
});