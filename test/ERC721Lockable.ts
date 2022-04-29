import  '@nomiclabs/hardhat-ethers'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from "chai"
import { Contract } from 'ethers';
import { ethers } from "hardhat";

describe("ERC721Lockable contract", function() {
  let owner: SignerWithAddress;
  let RACA: Contract;

  beforeEach(async () => {
    [owner] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("RadioCacaERC721");
    RACA = await Factory.deploy(
      "RadioCacaERC721",
      "RACANFT",
      owner.address,
      owner.address,
    );
  })

  it("Deployment should assign the total supply of tokens to the owner", async function() {
    const ownerBalance = await RACA.balanceOf(owner.address);
    expect(await RACA.totalSupply()).to.equal(ownerBalance);
  });
});
