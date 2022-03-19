const HDWalletProvider = require('@truffle/hdwallet-provider');
const privateKey = "";
const infuraKey = "";

module.exports = {
  networks: {
    rinkeby: {
      provider: () => new HDWalletProvider(
        privateKey,
        "https://rinkeby.infura.io/v3/" + infuraKey
      ),
      network_id: 4,
      gas: 3000000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    mainnet: {
      provider: () => new HDWalletProvider(
        privateKey,
        "https://mainnet.infura.io/v3/" + infuraKey
      ),
      network_id: 1,
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },
  mocha: {
    // timeout: 100000
  },
  compilers: {
    solc: {
      version: "0.8.4",    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    }
  },
  db: {
    enabled: false
  }
};
