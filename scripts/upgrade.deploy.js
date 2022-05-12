const { ethers, upgrades } = require("hardhat");

async function main() {
  const factory = await ethers.getContractFactory("MPBV2Upgradeable");
  console.log("Deploying NFT...");

  // 1.deploy logic 2. deploy proxyAdmin 3. deploy proxy
  const nft = await upgrades.deployProxy(factory);
  await nft.deployed();
  console.log("NFT deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
