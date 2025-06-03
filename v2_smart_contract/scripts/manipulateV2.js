require("dotenv").config()

const hre = require("hardhat")
const axios = require("axios")

// -- IMPORT HELPER FUNCTIONS & CONFIG -- //
const { getTokenAndContract, getPairContract, calculatePrice } = require('../helpers/helpers.js')
const { provider, uFactory, uRouter, sFactory, sRouter } = require('../helpers/initialization.js')

// -- CONFIGURE VALUES HERE -- //
const V2_FACTORY_TO_USE = uFactory
const V2_ROUTER_TO_USE = uRouter

const UNLOCKED_ACCOUNT = '0xdEAD000000000000000042069420694206942069' // SHIB account to impersonate 
const AMOUNT = '40500000000000' // 40,500,000,000,000 SHIB -- Tokens will automatically be converted to wei
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

async function main() {
  // Fetch contracts
  const {
    token0Contract,
    token1Contract,
    token0: ARB_AGAINST,
    token1: ARB_FOR
  } = await getTokenAndContract(process.env.ARB_AGAINST, process.env.ARB_FOR, provider)

  const pair = await getPairContract(V2_FACTORY_TO_USE, ARB_AGAINST.address, ARB_FOR.address, provider)

  // Fetch price of SHIB/WETH before we execute the swap
  const priceBefore = await calculatePrice(pair)

  

  pair.on("Swap", async (...params) => {

    // Fetch price of SHIB/WETH after the swap
    const priceAfter = await calculatePrice(pair)
  
    const data = {
      'Price Before': `1 WETH = ${Number(priceBefore).toFixed(0)} SHIB`,
      'Price After': `1 WETH = ${Number(priceAfter).toFixed(0)} SHIB`,
    }
  
    console.table(data)


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


  // pair.on("Swap", async (...params) => {
  //   console.log("sx1 swap event");
  //   console.log(params);

  //   const event = JSON.stringify({ address: params[6].emitter.target });
  //   console.log("sx1 JSON.stringify(event)", event);


  //   sendPostEvent(event);

  // });


  // await manipulatePrice([ARB_AGAINST, ARB_FOR], token0Contract)

  // // Fetch price of SHIB/WETH after the swap
  // const priceAfter = await calculatePrice(pair)

  // const data = {
  //   'Price Before': `1 WETH = ${Number(priceBefore).toFixed(0)} SHIB`,
  //   'Price After': `1 WETH = ${Number(priceAfter).toFixed(0)} SHIB`,
  // }



  // console.table(data)
}

async function manipulatePrice(_path, _token0Contract) {
  console.log(`\nBeginning Swap...\n`)

  console.log(`Input Token: ${_path[0].symbol}`)
  console.log(`Output Token: ${_path[1].symbol}\n`)

  const amount = hre.ethers.parseUnits(AMOUNT, 'ether')
  const path = [_path[0].address, _path[1].address]
  const deadline = Math.floor(Date.now() / 1000) + 60 * 20 // 20 minutes

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [UNLOCKED_ACCOUNT],
  })

  const signer = await hre.ethers.getSigner(UNLOCKED_ACCOUNT)

  const approval = await _token0Contract.connect(signer).approve(await V2_ROUTER_TO_USE.getAddress(), amount, { gasLimit: 50000 })
  await approval.wait()

  const swap = await V2_ROUTER_TO_USE.connect(signer).swapExactTokensForTokens(amount, 0, path, signer.address, deadline, { gasLimit: 125000 })
  await swap.wait()



  console.log(`Swap Complete!\n`)
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
