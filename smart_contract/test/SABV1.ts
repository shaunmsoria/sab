import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Signer } from "ethers";
import { SABV1 } from "../typechain-types/contracts/SABV1";
import { provider, uFactory, uRouter, sFactory, sRouter, accountNumber  } from "../helpers/initialisation";
import { reset } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import config from "../hardhat.config";



describe("SABV1", () => {

    type ERC20Address = string;
    type Factory_Router = {
        V2_ROUTER_02_ADDRESS: ERC20Address,
        FACTORY_ADDRESS: ERC20Address
    }

    let owner: Signer;
    let sabv1: SABV1;
    let token0: ERC20Address;
    let token1: ERC20Address;
    let account: string;
    let url: string = config.networks.hardhat.forking.url;

    
    beforeEach(async () => {
        // reset the alchemy network before each test 
        await reset(url, 18952975);

        [owner] = await ethers.getSigners();

        sabv1 = await ethers.getContractFactory("SABV1")
        .then((factory) => factory.deploy())
        .then((contract) => contract.waitForDeployment());


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
        let result;
        result = await sabv1.executeTrade(
            token0, token1, uRouter, sRouter, 1);

        expect(result.from).to.equal(account);
       }) 
    });
});