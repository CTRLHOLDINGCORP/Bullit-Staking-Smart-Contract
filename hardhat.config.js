require("@nomiclabs/hardhat-waffle");
require('dotenv').config({ path: __dirname + '/.env' })

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  defaultNetwork: "localhost",
  networks: {

    localhost: {
      url: "http://127.0.0.1:7545",
      accounts: [process.env.GANACHE_PRIVATE_KEY],
    },

    theta_testnet: {
      url: `https://eth-rpc-api-testnet.thetatoken.org/rpc`,
      accounts: [process.env.THETA_TESTNET_WALLET_PRIVATE_KEY],
      chainId: 365,
      gasPrice: 4000000000000
    },

    theta_mainnet: {
      url: `https://eth-rpc-api.thetatoken.org/rpc`,
      accounts: [process.env.THETA_MAINNET_WALLET_PRIVATE_KEY],
      chainId: 361,
      gasPrice: 4000000000000
    },
  },
  solidity: {
    version: "0.8.14",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
}
