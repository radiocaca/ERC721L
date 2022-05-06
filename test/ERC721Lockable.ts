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
    const block = await ethers.provider.getBlockNumber()
    await EIP5058.lockMint(owner.address, NFTId, block + 2);

    expect(await EIP5058.isLocked(NFTId)).eq(true);
  });

  it("Can not transfer when token is locked", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber()
    await EIP5058.lockMint(owner.address, NFTId, block + 3);

    // can not transfer when token is locked
    await expect(EIP5058.transferFrom(owner.address, alice.address, NFTId)).to.be.revertedWith(
      "ERC721L: token transfer while locked",
    );
  });

  it("isLocked works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber()
    await EIP5058.lockMint(owner.address, NFTId, block + 2);

    // isLocked works
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    await ethers.provider.send("evm_mine", []);
    expect(await EIP5058.isLocked(NFTId)).eq(false);
  });

  // it("lockFrom works", async function() {
  //   const NFTId = 0;
  //   let block = await ethers.provider.getBlockNumber()
  //   await EIP5058.lockMint(owner.address, NFTId, block + 2);
  //
  //   // lockFrom works
  //   // await ethers.provider.send("evm_mine", []);
  //   // block = await ethers.provider.getBlockNumber()
  //   await EIP5058.lockFrom(owner.address, NFTId, block + 4);
  // });

  it("unlockFrom works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber()
    await EIP5058.lockMint(owner.address, NFTId, block + 3);

    // unlock works
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    expect(await EIP5058.lockerOf(NFTId)).eq(owner.address);
    await EIP5058.unlockFrom(owner.address, NFTId);
    expect(await EIP5058.isLocked(NFTId)).eq(false);
  });

  it("lockApprove works", async function () {
    const NFTId = 0;
    await EIP5058.mint(owner.address, NFTId);
    await EIP5058.lockApprove(alice.address, NFTId);

    expect(await EIP5058.getLockApproved(NFTId)).eq(alice.address);
  });

  // it("Can lock while lockApproved", async function() {
  //   const NFTId = 0;
  //   const block = await ethers.provider.getBlockNumber()
  //   await EIP5058.lockMint(owner.address, NFTId, block + 2);
  //   await EIP5058.lockApprove(alice.address, NFTId);
  //
  // });

  it("setLockApproveForAll works", async function() {
    await EIP5058.setLockApprovalForAll(alice.address, true);
    expect(await EIP5058.isLockApprovedForAll(owner.address, alice.address)).eq(true);

    await EIP5058.setLockApprovalForAll(alice.address, false);
    expect(await EIP5058.isLockApprovedForAll(owner.address, alice.address)).eq(false);
  });
});
