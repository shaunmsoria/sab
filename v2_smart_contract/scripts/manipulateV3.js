require("dotenv").config();
const hre = require("hardhat");
const axios = require("axios");
const { ethers } = require("hardhat");

// Uniswap V3 interfaces
const IUniswapV3Pool = require('@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json');
const ISwapRouter = require('@uniswap/v3-periphery/artifacts/contracts/interfaces/ISwapRouter.sol/ISwapRouter.json');
const IUniswapV3Factory = require('@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Factory.sol/IUniswapV3Factory.json');

// Add this ABI for ERC20 with name, symbol, and decimals
const ERC20_ABI = [
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address) view returns (uint256)",
  "function transfer(address, uint256) returns (bool)",
  "function approve(address, uint256) returns (bool)",
  "function allowance(address, address) view returns (uint256)",
  "function transferFrom(address, address, uint256) returns (bool)",
  "event Transfer(address indexed from, address indexed to, uint256 amount)",
  "event Approval(address indexed owner, address indexed spender, uint256 amount)"
];

// Constants
const UNISWAP_V3_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const WHALE_ACCOUNT = "0xF977814e90dA44bFA03b6295A0616a897441aceC"; // Binance 8 wallet
const AMOUNT = "100000000000"; // 100 billion SHIB tokens
const FEE_TIER = 3000; // 0.3% fee tier

async function sendPostEvent(event) {
  const url = `http://localhost:4000/event`;
  console.log("Event data:", event);

  try {
    const response = await axios.post(url, event, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    console.log('Success:', response.data);
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error('Axios error:', error.message);
    } else {
      console.error('Unexpected error:', error);
    }
  }
}

// Calculate price from Uniswap V3 pool
async function calculateV3Price(poolContract, decimals0, decimals1) {
  const slot0 = await poolContract.slot0();
  const sqrtPriceX96 = slot0.sqrtPriceX96;

  try {
    // Convert sqrtPrice to a regular number
    const sqrtPriceNum = Number(sqrtPriceX96.toString()) / Math.pow(2, 96);
    const price = Math.pow(sqrtPriceNum, 2);

    // Adjust for decimals
    const adjustedPrice = price * Math.pow(10, Number(decimals1) - Number(decimals0));
    return adjustedPrice;
  } catch (error) {
    console.error("Error calculating price:", error);
    return 0;
  }
}

async function getTokensAndPool(token0Address, token1Address, fee) {
  // Get token contracts
  const token0 = await ethers.getContractAt(ERC20_ABI, token0Address);
  const token1 = await ethers.getContractAt(ERC20_ABI, token1Address);

  // Get token details
  const [symbol0, decimals0, symbol1, decimals1] = await Promise.all([
    token0.symbol(),
    token0.decimals(),
    token1.symbol(),
    token1.decimals(),
  ]);

  // Get UniswapV3 Factory
  const factoryAddress = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
  const factory = await ethers.getContractAt(
    IUniswapV3Factory.abi,
    factoryAddress
  );

  // Get pool address - check both orderings since tokens might be reversed
  let poolAddress = await factory.getPool(token0Address, token1Address, fee);
  let isReversed = false;

  if (poolAddress === ethers.ZeroAddress) {
    // Try reverse order
    poolAddress = await factory.getPool(token1Address, token0Address, fee);
    if (poolAddress === ethers.ZeroAddress) {
      throw new Error(`No pool exists for ${symbol0}-${symbol1} with ${fee / 10000}% fee`);
    }
    isReversed = true;
  }

  pool = await ethers.getContractAt(IUniswapV3Pool.abi, poolAddress);

  // Return in the original order requested
  if (!isReversed) {
    return {
      token0: {
        contract: token0,
        address: token0Address,
        symbol: symbol0,
        decimals: decimals0,
      },
      token1: {
        contract: token1,
        address: token1Address,
        symbol: symbol1,
        decimals: decimals1,
      },
      pool,
    };
  } else {
    return {
      token0: {
        contract: token0,
        address: token0Address,
        symbol: symbol0,
        decimals: decimals0,
      },
      token1: {
        contract: token1,
        address: token1Address,
        symbol: symbol1,
        decimals: decimals1,
      },
      pool,
      isReversed
    };
  }
}

async function main() {
  // Define tokens - SHIB and WETH
  const SHIB = "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE";
  const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

  // Get tokens and pool
  const { token0, token1, pool, isReversed } = await getTokensAndPool(SHIB, WETH, FEE_TIER);

  console.log(`Pool: ${token0.symbol}/${token1.symbol} with ${FEE_TIER / 10000}% fee`);
  console.log(`Pool address: ${pool.target}`);

  // Listen for swap events
  pool.on("Swap", async (...params) => {
    console.log("\nSwap event detected!");

    // Calculate price after swap
    const priceAfter = await calculateV3Price(
      pool,
      isReversed ? token1.decimals : token0.decimals,
      isReversed ? token0.decimals : token1.decimals
    );

    console.log(`Price after swap: 1 ${token1.symbol} = ${priceAfter.toLocaleString()} ${token0.symbol}`);

    // Format parameters for readability
    const eventData = {
      sqrtPriceX96: params[0].toString(),
      tick: params[1],
      amount0: isReversed
        ? ethers.formatUnits(params[3], token0.decimals)
        : ethers.formatUnits(params[2], token0.decimals),
      amount1: isReversed
        ? ethers.formatUnits(params[2], token1.decimals)
        : ethers.formatUnits(params[3], token1.decimals),
      sender: params[4],
      recipient: params[5]
    };

    console.table(eventData);

    // Add this helper function at the top of your file
    function bigIntSafeStringify(obj) {
      return JSON.stringify(obj, (key, value) => {
        if (typeof value === 'bigint') {
          return value.toString();
        }
        return value;
      });
    }

    // Convert the params
    const eventObj = {
      data: {
        sqrtPriceX96: params[0].toString(),
        tick: params[1].toString(),
        amount0: params[2].toString(),
        amount1: params[3].toString(),
        sender: params[4],
        recipient: params[5]
      },
      name: "Swap",
      address: pool.target.toString(),  // Convert to string
      decoded: true
    };

    const event = bigIntSafeStringify(eventObj);

    await sendPostEvent(event);
  });

  // Calculate price before swap
  const priceBefore = await calculateV3Price(
    pool,
    isReversed ? token1.decimals : token0.decimals,
    isReversed ? token0.decimals : token1.decimals
  );
  console.log(`Price before swap: 1 ${token1.symbol} = ${priceBefore.toLocaleString()} ${token0.symbol}`);

  // Execute swap
  await executeSwap(token0, token1, isReversed);

  // Keep script running to catch events
  console.log("Waiting for events (press Ctrl+C to exit)...");
}

async function executeSwap(token0, token1, isReversed) {
  console.log(`\nBeginning SHIB to WETH swap with whale account...\n`);

  const amount = ethers.parseUnits(AMOUNT, token0.decimals);
  const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20 minutes

  // Impersonate whale account
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [WHALE_ACCOUNT],
  });

  const signer = await hre.ethers.getSigner(WHALE_ACCOUNT);

  // Check balance before swap
  const balanceBefore = await token0.contract.balanceOf(signer.address);
  console.log(`${token0.symbol} balance before swap: ${ethers.formatUnits(balanceBefore, token0.decimals)}`);

  if (balanceBefore < amount) {
    console.log(`Whale doesn't have enough ${token0.symbol}. Setting balance manually...`);

    // Add some ETH for gas
    await hre.network.provider.request({
      method: "hardhat_setBalance",
      params: [
        WHALE_ACCOUNT,
        "0x" + (10n ** 22n).toString(16), // 10000 ETH
      ],
    });

    // Find a holder with lots of tokens to get SHIB from
    const holder = "0x8894E0a0c962CB723c1976a4421c95949bE2D4E3"; // Top SHIB holder

    // Impersonate the holder
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [holder],
    });

    const holderSigner = await ethers.getSigner(holder);

    // Transfer tokens to our whale
    await token0.contract.connect(holderSigner).transfer(
      WHALE_ACCOUNT,
      amount
    );

    // Stop impersonating the holder
    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [holder],
    });

    // Check balance again
    const newBalance = await token0.contract.balanceOf(signer.address);
    console.log(`New ${token0.symbol} balance: ${ethers.formatUnits(newBalance, token0.decimals)}`);
  }

  // Get Uniswap V3 Router contract
  const router = await ethers.getContractAt(
    ISwapRouter.abi,
    UNISWAP_V3_ROUTER
  );

  // Check WETH balance before swap
  const wethBefore = await token1.contract.balanceOf(signer.address);
  console.log(`${token1.symbol} balance before swap: ${ethers.formatUnits(wethBefore, token1.decimals)}`);

  // Approve router to spend SHIB
  console.log(`Approving ${ethers.formatUnits(amount, token0.decimals)} ${token0.symbol}...`);
  await token0.contract.connect(signer).approve(
    UNISWAP_V3_ROUTER,
    amount,
    { gasLimit: 500000 }
  );

  // Execute swap on Uniswap V3
  const swapParams = {
    tokenIn: token0.address,
    tokenOut: token1.address,
    fee: FEE_TIER,
    recipient: signer.address,
    deadline: deadline,
    amountIn: amount,
    amountOutMinimum: 0,
    sqrtPriceLimitX96: 0,
  };

  console.log(`Executing swap: ${ethers.formatUnits(amount, token0.decimals)} ${token0.symbol} -> ${token1.symbol}...`);
  try {
    const tx = await router.connect(signer).exactInputSingle(
      swapParams,
      { gasLimit: 5000000 }
    );

    console.log(`Swap transaction submitted: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Swap confirmed in block ${receipt.blockNumber}`);

    // Check WETH balance after swap
    const wethAfter = await token1.contract.balanceOf(signer.address);
    const wethGained = wethAfter - wethBefore;

    console.log(`${token1.symbol} balance after swap: ${ethers.formatUnits(wethAfter, token1.decimals)}`);
    console.log(`${token1.symbol} gained from swap: ${ethers.formatUnits(wethGained, token1.decimals)}`);

    // Calculate effective exchange rate
    const rate = Number(amount) / Number(wethGained);
    console.log(`Effective exchange rate: 1 ${token1.symbol} = ${rate / 10 ** (token0.decimals - token1.decimals)} ${token0.symbol}`);

  } catch (error) {
    console.error("Swap failed:", error.message);
    if (error.data) {
      console.error("Error data:", error.data);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});