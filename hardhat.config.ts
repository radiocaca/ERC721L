import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
require('@openzeppelin/hardhat-upgrades');

const { config } = require("dotenv");
const { resolve } = require("path");
config({ path: resolve(__dirname, "./.env") });

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
//   const accounts = await hre.ethers.getSigners();
//
//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

if (process.env.REPORT_GAS) {
  require("hardhat-gas-reporter");
}

if (process.env.REPORT_COVERAGE) {
  require("solidity-coverage");
}

const MNEMONIC = process.env.MNEMONIC || "";
const PRIVATEKEY = process.env.PRIVATEKEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
// const INFURA_API_KEY = process.env.INFURA_API_KEY || "";

const chainIds = {
  hardhat: 31337,
  ganache: 1337,
  mainnet: 1,
  ropsten: 3,
  rinkeby: 4,
  goerli: 5,
  bnbmain: 56,
  bnbtest: 97,
  okcmain: 66,
  okctest: 65,
};

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.8",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      accounts: {
        initialIndex: 0,
        mnemonic: MNEMONIC,
        path: "m/44'/60'/0'/0",
      },
      chainId: chainIds.hardhat,
    },
    mainnet: {
      url: "https://falling-frosty-dew.quiknode.pro/",
      chainId: chainIds.mainnet,
      accounts: [PRIVATEKEY],
    },
    bnbmain: {
      url: "https://spring-falling-water.bsc.quiknode.pro/",
      chainId: chainIds.bnbmain,
      accounts: [PRIVATEKEY],
    },
    bnbtest: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: chainIds.bnbtest,
      accounts: [PRIVATEKEY],
    },
    okcmain: {
      url: "https://exchainrpc.okex.org/",
      chainId: chainIds.okcmain,
      accounts: [PRIVATEKEY],
    },
    okctest: {
      url: "https://exchaintestrpc.okex.org/",
      chainId: chainIds.okctest,
      accounts: [PRIVATEKEY],
    },
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 100,
    showTimeSpent: true,
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  plugins: ["solidity-coverage"],
};
