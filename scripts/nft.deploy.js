const { deployContract } = require("./deploy.js");

async function main() {
  const nft = await deployContract("MPBV2", []);

  console.log("MPBV2 deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
