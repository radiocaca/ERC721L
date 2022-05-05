import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { EIP5058Mock } from "typechain-types";

describe("ERC721Lockable contract", function () {
  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let EIP5058: EIP5058Mock;

  beforeEach(async () => {
    [owner, alice] = await ethers.getSigners();

    const FF = await ethers.getContractFactory("EIP5058Factory");
    const Factory = await FF.deploy();

    const EIP5058Factory = await ethers.getContractFactory("EIP5058Mock");

    EIP5058 = await EIP5058Factory.deploy("Mock", "M", Factory.address);

    await Factory.boundDeploy(EIP5058.address);
  });

  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const ownerBalance = await EIP5058.balanceOf(owner.address);
    expect(await EIP5058.totalSupply()).to.equal(ownerBalance);
  });

  it("lockMint works", async function () {
    const NFTId = 0;
    const block = await ethers.provider.getBlock("latest");
    const expired = block.number + 1;
    await EIP5058.lockMint(owner.address, NFTId, expired);

    expect(await EIP5058.isLocked(NFTId)).eq(true);
  });

  it("Can not transfer when token is locked", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlock("latest");
    const expired = block.number + 1;
    await EIP5058.lockMint(owner.address, NFTId, expired);

    // can not transfer when token is locked
    await expect(EIP5058.transferFrom(owner.address, alice.address, NFTId)).to.be.revertedWith(
      "ERC721L: token transfer while locked",
    );
  });

  it("Can transfer when token is expired", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlock("latest");
    const expired = block.number + 1;
    await EIP5058.lockMint(owner.address, NFTId, expired);

    // can transfer when lock is expired
    await ethers.provider.send('evm_mine', []);
    await expect(EIP5058.transferFrom(owner.address, alice.address, NFTId)).to.be.revertedWith(
      "ERC721L: token transfer while locked",
    );
  });

  it("lockApprove works", async function () {
    const NFTId = 0;
    await EIP5058.mint(owner.address, NFTId);
    await EIP5058.lockApprove(alice.address, NFTId);

    expect(await EIP5058.getLockApproved(NFTId)).eq(alice.address);
  });
});
