const { deployContract } = require('./deploy.js');

async function main() {
  const greeter = await deployContract("RadioCacaERC721",
    ["RadioCacaERC721", "RACANFT", "0xDf9F44016355beeB1414012D4234522bb9Cd9E91",
      "0xDf9F44016355beeB1414012D4234522bb9Cd9E91"])

  console.log("RadioCacaERC721 deployed to:", greeter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
