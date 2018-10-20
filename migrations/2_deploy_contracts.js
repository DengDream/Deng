var IterableMapping = artifacts.require('./IterableMapping.sol');
var StarNotary = artifacts.require("./StarNotary.sol");

module.exports = function(deployer){
  deployer.deploy(IterableMapping).then(()=>{
    deployer.deploy(StarNotary);
  });
  deployer.link(IterableMapping,StarNotary);
}
