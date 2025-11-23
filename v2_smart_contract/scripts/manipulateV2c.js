require("dotenv").config()

const hre = require("hardhat")
const axios = require("axios")

// -- IMPORT HELPER FUNCTIONS & CONFIG -- //
const { getTokenAndContract, getPairContract, calculatePrice } = require('../helpers/helpers.js')
const { provider, uFactory, uRouter, sFactory, sRouter } = require('../helpers/initialization.js')

// -- CONFIGURE VALUES HERE -- //
const V2_FACTORY_TO_USE = uFactory
const V2_ROUTER_TO_USE = uRouter

// USDC hot wallet -> 0x2d4d2A025b10C09BDbd794B4FCe4F7ea8C7d7bB4
// USDC address -> 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

// const UNLOCKED_ACCOUNT = '0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341' // SHIB account to impersonate 
// const UNLOCKED_ACCOUNT = '0xF977814e90dA44bFA03b6295A0616a897441aceC' // SHIB account to impersonate 
const UNLOCKED_ACCOUNT = '0x835678a611B28684005a5e2233695fB6cbbB0007' // SHIB account to impersonate 
// const AMOUNT = '405000000000000' // 40,500,000,000,000 SHIB -- Tokens will automatically be converted to wei
// const AMOUNT = '40050000000' // 40,500,000,000,000 SHIB -- Tokens will automatically be converted to wei
// const AMOUNT = '100000' // 40,500,000,000,000 SHIB -- Tokens will automatically be converted to wei
const AMOUNT = '200000' // 40,500,000,000,000 SHIB -- Tokens will automatically be converted to wei
// const AMOUNT = '400500000000000' // 40,500,000,000,000 SHIB -- Tokens will automatically be converted to wei
// const AMOUNT = '40500000000000000' // 40,500,000,000,000 SHIB -- Tokens will automatically be converted to wei


async function sendPostEvent(event) {
  const url = `http://localhost:4000/event`;

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

async function ensureAccountHasETH(address) {
  const balance = await provider.getBalance(address);
  if (balance < hre.ethers.parseEther("1.0")) {
    await hre.network.provider.send("hardhat_setBalance", [
      address,
      "0x" + (1n * 10n ** 18n).toString(16) // 1 ETH
    ]);
  }
}

async function main() {
  // Fetch contracts
  const {
    token0Contract,
    token1Contract,
    token0: ARB_AGAINST,
    token1: ARB_FOR
  } = await getTokenAndContract(process.env.ARB_AGAINST, process.env.ARB_FOR, provider);

  const pair = await getPairContract(V2_FACTORY_TO_USE, ARB_AGAINST.address, ARB_FOR.address, provider);
  console.log("sx1 pair", pair);

  // Fetch price of SHIB/WETH before we execute the swap
  const priceBefore = await calculatePrice(pair)

  

  pair.on("Swap", async (...params) => {

    // Fetch price of SHIB/WETH after the swap
    const priceAfter = await calculatePrice(pair)
  


    console.log("sx1 swap event");
    console.log(params);

    console.log("sx1 params[0]", params[0]);
    console.log("sx1 params[1]", params[1]);
    console.log("sx1 params[2]", params[2]);
    console.log("sx1 params[3]", params[3]);
    console.log("sx1 params[4]", params[4]);
    console.log("sx1 params[5]", params[5]);
    console.log("sx1 params[6]", params[6]);

    const event = JSON.stringify({
      event: {
      },
      data: {
        amount0In: params[1].toString(),
        amount1In: params[2].toString(),
        amount0Out: params[3].toString(),
        amount1Out: params[4].toString(),
        to: params[0].toString(),
        sender: params[5].toString(),
      },
      name: params[6].filter,
      address: params[6].emitter.target, 
      decoded: true 
    });
    console.log("sx1 JSON.stringify(event)", event);

    sendPostEvent(event);
  });

  await manipulatePrice([ARB_AGAINST, ARB_FOR], token0Contract)


}

// Helper function to get whale addresses for common tokens
function getWhaleAddressForToken(symbol) {
  const whales = {
    'USDC': '0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503', // Circle
    'WETH': '0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E', // Binance
    'SHIB': '0xdEAD000000000000000042069420694206942069', // Big SHIB holder
    'WBTC': '0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656', // Binance
    // Add more as needed
  };
  
  return whales[symbol];
}

async function manipulatePrice(_path, _token0Contract) {
  console.log(`\nBeginning Swap...\n`);

  console.log(`Input Token: ${_path[0].symbol}`);
  console.log(`Output Token: ${_path[1].symbol}\n`);

  // 1. Get token decimals and use them properly
  const token0Decimals = await _token0Contract.decimals();
  console.log(`Token decimals: ${token0Decimals}`);

  // 2. Parse amount with correct decimals
  const amount = hre.ethers.parseUnits(AMOUNT, token0Decimals);
  console.log(`Amount in base units: ${amount.toString()}`);
  
  const path = [_path[0].address, _path[1].address];
  const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20 minutes

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [UNLOCKED_ACCOUNT],
  });

  const signer = await hre.ethers.getSigner(UNLOCKED_ACCOUNT);
  
  // 3. Check balance before proceeding
  const balance = await _token0Contract.balanceOf(UNLOCKED_ACCOUNT);
  console.log(`Account balance: ${hre.ethers.formatUnits(balance, token0Decimals)} ${_path[0].symbol}`);
  
   // Convert to BigInt for comparison
  const balanceBigInt = BigInt(balance.toString());
  const amountBigInt = BigInt(amount.toString());
  
  if (balanceBigInt < amountBigInt) {
    console.error(`ERROR: Account has insufficient balance`);
    console.log(`Required: ${hre.ethers.formatUnits(amount, token0Decimals)}`);
    console.log(`Available: ${hre.ethers.formatUnits(balance, token0Decimals)}`);
    
    // 4. Fund the account if needed (for testing purposes)
    console.log("Attempting to fund the account...");
    // Find a whale address for this token
    const whaleAddress = getWhaleAddressForToken(_path[0].symbol);
    if (whaleAddress) {
      await fundAccountFromWhale(_token0Contract, whaleAddress, UNLOCKED_ACCOUNT, amount);
      console.log("Account funded successfully");
    } else {
      throw new Error("Insufficient funds and no whale address found");
    }
  }

  // 5. Approve with sufficient amount
  console.log("Approving token transfer...");
  const routerAddress = await V2_ROUTER_TO_USE.getAddress();
  const approval = await _token0Contract.connect(signer).approve(
    routerAddress, 
    amount,
    { gasLimit: 125000 }
  );
  await approval.wait();
  
  // 6. Check allowance after approval
  const allowance = await _token0Contract.allowance(UNLOCKED_ACCOUNT, routerAddress);
  console.log(`Allowance: ${hre.ethers.formatUnits(allowance, token0Decimals)} ${_path[0].symbol}`);

  const allowanceBigInt = BigInt(allowance.toString());
  
  // if (allowanceBigInt < amountBigInt) {
  //   throw new Error("Approval failed - allowance is less than required amount");
  // }

  console.log("Executing swap...");
  const swap = await V2_ROUTER_TO_USE.connect(signer).swapExactTokensForTokens(
    amount, 
    0, // Accept any amount of output tokens
    path, 
    signer.address, 
    deadline, 
    { gasLimit: 125000 }
  );
  const receipt = await swap.wait();

  console.log(`Swap Complete!\n`);
  console.log(`Receipt hash: ${receipt.hash}`);
}

// Helper function to fund an account from a whale
async function fundAccountFromWhale(tokenContract, whaleAddress, recipientAddress, amount) {

  await ensureAccountHasETH(whaleAddress);
  await ensureAccountHasETH(recipientAddress);


  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [whaleAddress],
  });
  
  const whaleSigner = await hre.ethers.getSigner(whaleAddress);
  const whaleBalance = await tokenContract.balanceOf(whaleAddress);
  
  console.log(`Whale balance: ${whaleBalance.toString()}`);

  const whaleBalanceBigInt = BigInt(whaleBalance.toString());
  const amountBigInt = BigInt(amount.toString());

  if (whaleBalanceBigInt < amountBigInt ) {
    throw new Error("Whale doesn't have enough tokens");
  }
  
  await tokenContract.connect(whaleSigner).transfer(recipientAddress, amount);
  
  await hre.network.provider.request({
    method: "hardhat_stopImpersonatingAccount",
    params: [whaleAddress],
  });
};


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
