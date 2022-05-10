# RadioCaca NFT Protocol

Implement: [EIP-5058](https://github.com/ethereum/EIPs/pull/5058/files)

- AccessControl
- Burnable
- Pausable
- Lockable
- NFT Royalty Standard (ERC2981)
- Redeemer: Allows holders of ERC721 tokens to redeem rights to some claim; for
  example, the right to mint a token of some other collection.
- Multiple tokenURI management
- Contract URI
- Tokens withdrawal within the contract
- Bound NFT

## Testing

Try running some of the following tasks:

```shell
npm run lint
npx hardhat test
npx hardhat compile
npx hardhat run scripts/nft.deploy.js --network bnbtest
npx hardhat verify --network bnbtest <contract address> "constructor argument 1" "constructor argument 2"..
npx hardhat clean
npx hardhat node
npx hardhat help
```
