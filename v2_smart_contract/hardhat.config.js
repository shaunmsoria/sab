// require("dotenv").config()
// require("@nomicfoundation/hardhat-toolbox");

// module.exports = {
//   // solidity: "0.8.4",
//   solidity: "0.8.30",
//   networks: {
//     hardhat2: {
//       // url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
//       url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
//       accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
//       // blockGasLimit: 10000000,
//       // gas: 5000000
//     },
//     sepolia: {
//       // url: `https://eth-sepolia.g.alchemy.com/v2/kDsQmG9DLRQC6_Ysaah0tPKqo3bZFAKw`,
//       url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
//       accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
//     },
//     hardhat: {
//       forking: {
//         url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
//         // url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
//         gas: "auto",
//         gasPrice: "auto"
//       },
//     },
//   }
// };
require("dotenv").config()
require("@nomicfoundation/hardhat-toolbox");
// import { configVariable } from "hardhat/config";

module.exports = {
  // solidity: "0.8.4",
    solidity: {
    version: "0.8.30",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }},
  networks: {
    hardhat2: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      // url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1,
      gasPrice: "auto"
      // blockGasLimit: 10000000,
      // gas: 5000000
    },
    sepolia: {
      // url: `https://eth-sepolia.g.alchemy.com/v2/kDsQmG9DLRQC6_Ysaah0tPKqo3bZFAKw`,
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    hardhat: {
      forking: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
        // url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
        gas: "auto",
        gasPrice: "auto"
      },
    },
  },
  libraries: {
    // This will be populated during deployment
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
