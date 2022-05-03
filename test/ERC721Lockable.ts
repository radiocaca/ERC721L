import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { RadioCacaERC721 } from "typechain-types";

describe("ERC721Lockable contract", function () {
  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let RACA: RadioCacaERC721;

  beforeEach(async () => {
    [owner, alice] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("RadioCacaERC721");
    RACA = await Factory.deploy("RadioCacaERC721", "RACANFT", owner.address, owner.address);
  });

  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const ownerBalance = await RACA.balanceOf(owner.address);
    expect(await RACA.totalSupply()).to.equal(ownerBalance);
  });

  it("Could not transfer when token is locked", async function () {
    const NFTId = 0;
    await RACA.mint(owner.address, NFTId);

    const provider = ethers.getDefaultProvider();
    const latestBlock = await provider.getBlock("latest");
    const ts = latestBlock.timestamp + 15000;

    await RACA.lockFrom(owner.address, NFTId, ts);

    // could not transfer when token is locked
    await expect(RACA.transferFrom(owner.address, alice.address, NFTId)).to.be.revertedWith(
      "ERC721L: token transfer while locked",
    );
  });

  it("LockApprove works", async function () {
    const NFTId = 0;
    await RACA.mint(owner.address, NFTId);
    await RACA.lockApprove(alice.address, NFTId);

    expect(await RACA.getLockApproved(NFTId)).eq(alice.address);
  });
});
