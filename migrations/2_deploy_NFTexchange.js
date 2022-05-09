const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const NFTexchange = artifacts.require('NFTexchange');

module.exports = async function (deployer) {
  const instance = await deployProxy(NFTexchange, { deployer });
  console.log('Deployed', instance.address);
};