import { HardhatUserConfig } from "hardhat/config";
import * as dotenv from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
// require('hardha');

dotenv.config();
export default {
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/384158242f384bcbb27cbb663fbca37e" || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    hardhat: {
      gas: 1000000000000,
      gasPrice: 10000000000,
      initialBaseFeePerGas : 7,
      allowUnlimitedContractSize: true,
    },
    FUJI: {
      url: "https://avalanche-fuji.drpc.org/",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    matic: {
      url: "https://rpc-mumbai.maticvigil.com/",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    // localhost: {
    //   url: "http://127.0.0.1:8545",
    // },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    // rinkeby: {
    //   url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
    //   accounts: [`0x${process.env.PVTKEY}`],
    // },
    testnet: {
      url: "https://sepolia.infura.io/v3/a9f5841536114cf7a67969365e45ad69",
      // chainId: 97,
      // gasPrice: 20000000000,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: process.env.API,
  },

  // solidity: {
  //   compilers : 

  //   [
  //       {version: "0.8.18"},
  //       {version: "0.6.6"}

  //   ],
  
  //   settings: {
  //     optimizer: {
  //       enabled: true,
  //       runs: 200,
      
  //     },
  //     viaIR : true
  //   },
  // },


  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 500,
            details: {
              yul: true,
              yulDetails: {
                stackAllocation: true,
                optimizerSteps: "dhfoDgvulfnTUtnIf"
              }
            }
          },
          viaIR: true,
        },
      },
    ],
  },

// contractSizer: {
//   alphaSort: true,
//   disambiguatePaths: false,
//   runOnCompile: true,
//   strict: true,
//   only: ['Dabbler',"MarketPlace"],
// }
}
