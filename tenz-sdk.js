/**
 *
 * @desc Tenzorum TSNN Client SDK - https://tenzorum.org
 * @authors:
 *  Radek Ostrowski
 *  Mark Pereira
 *
 **/

const Web3 = require('web3');
let web3 = new Web3();

const emptyAddress = '0x0000000000000000000000000000000000000000';

const ethUtils = require('ethereumjs-util');
const utils = require('web3-utils');
const fetch = require('node-fetch');

let RELAYER_URL;
let isInitialised = false;

const zeroWei = 0;
const noData = "0x00";
const rewardTypeEther = "0x0000000000000000000000000000000000000000";
const noncesABI = [{"constant": true, "inputs": [{ "name": "", "type": "address" }], "name": "nonces", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "stateMutability": "view", "type": "function" }];

let privateKey;
let publicAddress;
let targetContractAddress;

const initSdk = (_privateKey, _contractAddress, _relayerUrl) => {
    if(!_web3){
        web3.setProvider(new web3.providers.HttpProvider(`https://rinkeby.infura.io/rqmgop6P5BDFqz6yfGla`));
    } else {
        web3 = _web3;
    }
    targetContractAddress = _contractAddress;
    privateKey = Buffer.from(_privateKey, 'hex');
    publicAddress = ethUtils.bufferToHex(ethUtils.privateToAddress(privateKey));
    RELAYER_URL = _relayerUrl;
    isInitialised = true;
};

const preparePayload = async (targetWallet, from, to, value, data, rewardType, rewardAmount) => {
    if(!isInitialised) console.log("ERROR: SDK not initialized");

    const noncesInstance = new web3.eth.Contract(noncesABI, targetWallet);
    const nonce = await noncesInstance.methods.nonces(from).call();
    const hash = ethUtils.toBuffer(utils.soliditySha3(targetWallet, from, to, value, data, rewardType, rewardAmount, nonce));

    const signedHash = ethUtils.ecsign(ethUtils.hashPersonalMessage(hash), privateKey);

    let payload = {};
    payload.v = ethUtils.bufferToHex(signedHash.v);
    payload.r = ethUtils.bufferToHex(signedHash.r);
    payload.s = ethUtils.bufferToHex(signedHash.s);
    payload.from = from;
    payload.to = to;
    payload.value = value.toString();
    payload.data = data;
    payload.rewardType = rewardType;
    payload.rewardAmount = rewardAmount.toString();

    const json = JSON.stringify(payload);
    console.log(json);

    return json;
}

const prepareCreateStarData = async (name, ra, dec, mag, starstory, tokenId, owner) => {
    const encoded = await web3.eth.abi.encodeFunctionCall({
        name: 'createStarMeta',
        type: 'function',
        inputs: [{
            type: 'string',
            name: '_name'
        }, {
            type: 'string',
            name: '_ra'
        }, {
            type: 'string',
            name: '_dec'
        }, {
            type: 'string',
            name: '_mag'
        }, {
            type: 'string',
            name: '_starstory'
        }, {
            type: 'uint256',
            name: '_tokenId'
        }, {
            type: 'address',
            name: '_owner'
        }]
    }, [name, ra, dec, mag, starstory, tokenId, owner]);
    return encoded;
};


/**
 * @desc gasless transaction call
 * @method relayTX
 * @param  {Object}  payload
 * @returns {String}  transaction hash
 */
const relayTx = async (payload) => {
    const res = await fetch(`${RELAYER_URL}/execute/${targetContractAddress}`, {
        method: 'POST',
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
        body: payload
    });
    const json = JSON.parse(await res.text());
    console.log(json);
    return json;
};

const createStar = async (name, ra, dec, mag, starstory, tokenId) => {
    const data = await prepareCreateStarData(name, ra, dec, mag, starstory, tokenId, publicAddress);
    return relayTx(await preparePayload(targetContractAddress, publicAddress, targetContractAddress, zeroWei, data, rewardTypeEther, zeroWei));
};
