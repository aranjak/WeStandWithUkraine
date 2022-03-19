const StandWithUkraine = artifacts.require("StandWithUkraine");

module.exports = async function (deployer) {
  const base = "https://ogl-nft.s3.eu-central-1.amazonaws.com/standwithukraine/metadata/";
  const contract = "https://ogl-nft.s3.eu-central-1.amazonaws.com/standwithukraine/collection.json";
  await deployer.deploy(StandWithUkraine, base, contract);
  await StandWithUkraine.deployed();
};
