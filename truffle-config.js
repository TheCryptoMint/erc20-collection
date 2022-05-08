require('dotenv').config();
require('@babel/register');
require('babel-polyfill');

const safeStringify = require('fast-safe-stringify');
const Web3 = require('web3');
const HDWalletProvider = require("@truffle/hdwallet-provider");

const { env } = process;
// const { web3 } = Web3;

// move the config here
// console.log(`process.env.MINTER_ADDRESS_LOCALHOST = ${safeStringify(env)}`);
// console.log(`50 gwei = ${ Web3.utils.toWe/**/i("50", "gwei")}`);
// console.log(`2nd param = ${Web3.utils.toWei('1', 'Ether')}`);
// console.log(`env.TCM_MINTER_ADDRESS = ${env.TCM_MINTER_ADDRESS}`);

// const HDWalletProvider = require("@truffle/hdwallet-provider");
// const NETWORK_ID = '5777';
// const GASLIMIT = '1158500000';
// const URL = 'http://127.0.0.1:7545'; // If you're running full node you can set your node's rpc url.
// const PRIVATE_KEY = 'fc2b39d0211910ae9af89d19f781e44f050844808ddc4947823aa7ca62c3d7e8';


const mnemonic = 'burger explain stand much ignore cook super subject stairs pave obey raw';
// const provider = new HDWalletProvider(mnemonic, "http://localhost:7475", 0, 8); // , true, "m/44'/137'/0'/0/");

const getWalletProvider = networkName => {
  const endpoint = `wss://${networkName}.infura.io/ws/v3/${env.INFURA_API_KEY}`;
  return new HDWalletProvider(env.MNEMONIC, endpoint, env.MINTER_GANACHE_INDEX);
};
// MORALIS_SPEEDY_NODE_KEY
const getBSCWalletProvider = networkName => {
  const providerOrUrl = (
    networkName === 'testnet' ?
    'https://speedy-nodes-nyc.moralis.io/77073f788332f085f441df3f/bsc/testnet' :
    // 'https://data-seed-prebsc-2-s3.binance.org:8545/' :
    // 'https://data-seed-prebsc-2-s1.binance.org:8545/' :
    `https://bsc-dataseed1.binance.org`
  );
  // https://data-seed-prebsc-1-s1.binance.org:8545/
  // const provider = new HDWalletProvider({
  //   // mnemonic: {
  //   //   phrase: env.MNEMONIC,
  //   // },
  //   providerOrUrl: endpoint,
  //   privateKeys: ['b71cd43dac1eaa76a653b8024e0f8359a1aa8406ce5301580479b8c9448dca11'],

  // });b71cd43dac1eaa76a653b8024e0f8359a1aa8406ce5301580479b8c9448dca11
  // const privateKeys = ['0xb71cd43dac1eaa76a653b8024e0f8359a1aa8406ce5301580479b8c9448dca11'];
  // b71cd43dac1eaa76a653b8024e0f8359a1aa8406ce5301580479b8c9448dca11
  // const provider = new HDWalletProvider(privateKeys, endpoint);
  console.log(`providerOrUrl=${providerOrUrl}`);
  const provider = new HDWalletProvider({
    mnemonic: {
      phrase: env.MNEMONIC,
    },
    providerOrUrl,
    // privateKeys,
    addressIndex: 0,
    numberOfAddresses: 1,
  });
  return provider;
  // return new HDWalletProvider(env.MNEMONIC, endpoint);
  // return new HDWalletProvider(mnemonic, endpoint, 1);
  // return new HDWalletProvider(env.MNEMONIC, endpoint, 15);
  // return new HDWalletProvider(env.MNEMONIC, endpoint, 0);
};

module.exports = {
  api_keys: {
    etherscan: env.ETHERSCAN_API_KEY,
    bscscan: env.BSCSCAN_API_KEY,
  },
  networks: {
    development: {
      // provider: () =>
      //   new HDWalletProvider(mnemonic, "http://127.0.0.1:7545", 0, 8),
      host: "127.0.0.1",
      port: 7545,
      // port: 8485, // 7475?
      network_id: "*", // Any network (default: none)
      from: `${ env.MINTER_ADDRESS_LOCALHOST }`,
      gasPrice: '0x64',
      gas: 6721975 // gas limit
    },
    bscTestnet: {
      provider: () => getBSCWalletProvider('testnet'),
      // from: `${ env.MINTER_ADDRESS }`,
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      networkCheckTimeout: 1000000,
      // chainId: 97,
      // gasPrice: Web3.utils.toWei('20', 'gwei'),
      // gas: 460000,
      gas: 25500000,
      // networkCheckTimeoutnetworkCheckTimeout: 10000,
      skipDryRun: true
    },
    bsc: {
      provider: () => getBSCWalletProvider('mainnet'),
      from: `${ env.MINTER_ADDRESS }`,
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    mainnet: {
      provider: () => getWalletProvider('mainnet'),
      network_id: 1,
      from: `${ env.MINTER_ADDRESS }`,
      // gas: 8000000,
      gasPrice: Web3.utils.toWei('115', 'gwei'),
      gas: 5750000, // Gas limit used for deploys. Default is 4712388.
      // gasPrice: 165000000000, //Gas price in Wei
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: false,    // Skip dry run before migrations? (default: false for public nets )
      networkCheckTimeout: 1000000, // see if this works...  https://github.com/trufflesuite/truffle/issues/3468
    },
    kovan: {
      provider: () => getWalletProvider('kovan'),
      network_id: 42,       // Ropsten's id
      from: `${ env.MINTER_ADDRESS }`,
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    ropsten: {
      provider: () => getWalletProvider('ropsten'),
      // gas: 5000000,
      gas: 8000000,
      // gasPrice: 25000000000,
      gasPrice: Web3.utils.toWei("50", "gwei"),
      network_id: 3,       // Ropsten's id
      from: `${ env.MINTER_ADDRESS }`,
      // gas: 1200000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true,     // Skip dry run before migrations? (default: false for public nets )
      // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
    },
    rinkeby: {
      provider: () => getWalletProvider('rinkeby'),
      // gas: 5000000,
      gas: 10000000,
      gasPrice: 25000000000,
      network_id: 4,       // rinkeby's id
      from: `${ env.MINTER_ADDRESS }`,
      // gas: 1200000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      networkCheckTimeout: 1000000, // see if this works...  https://github.com/trufflesuite/truffle/issues/3468
      skipDryRun: true,     // Skip dry run before migrations? (default: false for public nets )
      // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
    },
    goerli: {
      provider: () => getWalletProvider('goerli'),
      network_id: 5, // eslint-disable-line camelcase
      // gas: 266000,
      gas: 8500000,
      // gasPrice: 25000000000,
      gasPrice: Web3.utils.toWei("50", "gwei"),
      // gas: 10000000,
      // gasPrice: 25000000000,
      from: `${ env.MINTER_ADDRESS }`,
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      networkCheckTimeout: 1000000, // see if this works...  https://github.com/trufflesuite/truffle/issues/3468
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
  },
  // contracts_directory: './src/contracts/legacy/',
  // contracts_build_directory: './src/abis-legacy/',
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',
  compilers: {
    solc: {
      optimizer: {
        enabled: true,
        runs: 200
        // runs: 50
      },
      version: "^0.8.0"
    },
  },
  plugins: [
    "truffle-contract-size",
    "truffle-plugin-verify",
  ]
};
