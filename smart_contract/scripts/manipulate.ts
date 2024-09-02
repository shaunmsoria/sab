// import { ethers } from "hardhat";
import { ethers, Contract } from "ethers";
import hre from "hardhat";
import dotenv from "dotenv";
import { provider, uFactory, uRouter, sFactory, sRouter } from '../helpers/initialisation';
import IERC20 from '@openzeppelin/contracts/build/contracts/ERC20.json';
import IUniswapV2Pair from '@uniswap/v2-core/build/IUniswapV2Pair.json';
import Big from "big.js";
import axios from 'axios';

const UNLOCKED_ACCOUNT = '0xdEAD000000000000000042069420694206942069'; // SHIB account to impersonate
const AMOUNT = '40500000000000'; // 40,500,000,000,000 SHIB -- Tokens will automatically be converted to wei
const deadline = Math.floor(Date.now() / 1000) + 60 * 20 // 20 minutes
const shibAddress = '0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE';
const wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

const path = [
  shibAddress,
  wethAddress
];





async function impersonateAccount(account: string) {
  // await ethers.provider.send("hardhat_impersonateAccount", [account]);
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [account],
  })
};

type Provider = {
  provider: any;
};

type Token = {
  address: string,
  decimals: number,
  symbol: string,
  name: string
}

async function getTokenAndContract(_token0Address: string, _token1Address: string, _provider: Provider) {

  const token0Contract = new ethers.Contract(_token0Address, IERC20.abi, _provider)
  const token1Contract = new ethers.Contract(_token1Address, IERC20.abi, _provider)

  const token0 = {
    address: _token0Address,
    decimals: 18,
    symbol: await token0Contract.symbol(),
    name: await token0Contract.name()
  }

  const token1 = {
    address: _token1Address,
    decimals: 18,
    symbol: await token1Contract.symbol(),
    name: await token1Contract.name()
  }

  return { token0Contract, token1Contract, token0, token1 }
};

async function getPairAddress(_V2Factory: Contract, _token0: string, _token1: string) {
  const pairAddress = await _V2Factory.getPair(_token0, _token1)
  return pairAddress
}

async function getPairContract(_V2Factory: Contract, _token0: string, _token1: string, _provider: Provider) {
  const pairAddress = await getPairAddress(_V2Factory, _token0, _token1)
  const pairContract = new ethers.Contract(pairAddress, IUniswapV2Pair.abi, _provider)
  return pairContract
}

async function getReserves(_pairContract: Contract) {
  const reserves = await _pairContract.getReserves()
  return [reserves.reserve0, reserves.reserve1]
}


async function calculatePrice(_pairContract: Contract) {
  const [x, y] = await getReserves(_pairContract)
  return Big(x).div(Big(y))
}

async function sendPostEvent(event: any) {
  const url = `http://localhost:4000/event`;

  // const data = JSON.stringify(event);

  console.log("sx1 event pre post request", event);

  try {
    const response = await axios.post(url, event, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('Sucess:', response.data);
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error('Axios error:', error.message);
    } else {
      console.error('Unexpected error:', error)
    }

  }


};


async function main() {

  // Impersonate the account
  await impersonateAccount(UNLOCKED_ACCOUNT);

  const signer = await hre.ethers.getSigner(UNLOCKED_ACCOUNT);
  // const signer = await ethers.getSigner(UNLOCKED_ACCOUNT);

  const {
    token0Contract,
    token1Contract,
    token0,
    token1
  } = await getTokenAndContract(
    '0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE',
    '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    provider
  );

  const amount = hre.ethers.parseUnits(AMOUNT, 'ether')

  const pairContract = await getPairContract(uFactory, shibAddress, wethAddress, provider);

  const priceBefore = await calculatePrice(pairContract);

  console.log("sx1 priceBefore", Number(priceBefore).toFixed(0));


  // pairContract.on("Swap", async  (...params) => {

  //     sendPostEvent(params);

  // });


  pairContract.on("Swap", async (...params) => {
    console.log("sx1 swap event");
    console.log(params);

    const event = JSON.stringify({ address: params[6].emitter.target });
    console.log("sx1 JSON.stringify(event)", event);


    sendPostEvent(event);

  });


  // console.log("sx1 provider", provider);
  // console.log("sx1 signer value", signer);
  // console.log("sx1 token0Contract", token0Contract);
  // console.log("sx1 token1Contract", token1Contract);
  // console.log("sx1 token0", token0);
  // console.log("sx1 token1", token1);

  // const approval = await token0Contract.connect(signer).approve(await uRouter.getAddress(), AMOUNT, { gasLimit: 50000})

  const approval = await token0Contract.connect(signer).approve('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', amount, { gasLimit: 50000 })
  await approval.wait()
  // console.log("sx1 approval", approval);

  // console.log("sx1 amount", amount);
  console.log("sx1 path", path);
  // console.log("sx1 deadline", deadline);

  const swap = await uRouter.connect(signer).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, signer.address, deadline, { gasLimit: 125000 })
  await swap.wait();

  // console.log("sx1 swap", swap);

  // console.log("sx1 token1Contract", token1Contract);

  const priceAfter = await calculatePrice(pairContract);

  console.log("sx1 priceAfter", Number(priceAfter).toFixed(0));




};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});