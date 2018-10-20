var HDWalletProvider = require('truffle-hdwallet-provider');

var mnemonic = 'drastic chase unlock digital feature dynamic prize injury stable spend opera track';

module.exports = {
  networks: {
    development:{
      host:"localhost",
      port:"8545",
      network_id:"*",
      gas:4500000,
      gasPrice:10000000000,
    },
    rinkeby:{
    provider:function(){
      return new HDWalletProvider(mnemonic,'https://rinkeby.infura.io/v3/7b714a0f58894569ae61efed42eb6769')
    },
    network_id: 4,
    gas:4500000,
    gasPrice:10000000000,
  }
  }
};
