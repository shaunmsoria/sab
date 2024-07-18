import config from "../tsconfig.json";
import IUniswapV2Router02 from '@uniswap/v2-periphery/build/IUniswapV2Router02.json';
import IUniswapV2Factory from '@uniswap/v2-core/build/IUniswapV2Factory.json';
import { ethers } from "hardhat";
import dotenv from "dotenv";

dotenv.config();

type Provider = {
    provider: any;
};

let provider: Provider;
const accountNumber = `${process.env.ACCOUNT_NUMBER}`;
const alchemy = `${process.env.ALCHEMY_API_KEY}`
// const alchemy = `${process.env.SEPOLIA_ALCHEMY_API_KEY}`

if (config.PROJECT_SETTINGS.isLocal) {
    provider = new ethers.WebSocketProvider(`ws://127.0.0.1:8545/`)
} else {
    provider = new ethers.WebSocketProvider(`wss://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`);
    // provider = new ethers.WebSocketProvider(`wss://eth-sepolia.g.alchemy/v2/${process.env.SEPOLIA_ALCHEMY_API_KEY}`);
}

const uFactory = new ethers.Contract(config.UNISWAP.FACTORY_ADDRESS, IUniswapV2Factory.abi, provider);
const uRouter = new ethers.Contract(config.UNISWAP.V2_ROUTER_02_ADDRESS, IUniswapV2Router02.abi, provider);
const sFactory = new ethers.Contract(config.SUSHISWAP.FACTORY_ADDRESS, IUniswapV2Factory.abi, provider);
const sRouter = new ethers.Contract(config.SUSHISWAP.V2_ROUTER_02_ADDRESS, IUniswapV2Router02.abi, provider);




export {
    provider,
    uFactory,
    uRouter,
    sFactory,
    sRouter,
    accountNumber,
    alchemy
};



