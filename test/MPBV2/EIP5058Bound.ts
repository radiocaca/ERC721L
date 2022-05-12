import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MPBV2, ERC721Bound } from "typechain-types";

describe("MPB EIP5058Bound contract", function () {
  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let EIP5058Bound: MPBV2;
  let NFTBound : ERC721Bound;

  beforeEach(async () => {
    [owner, alice] = await ethers.getSigners();

    const FF = await ethers.getContractFactory("ERC5058Factory");
    const Factory = await FF.deploy();

    const EIP5058BoundFactory = await ethers.getContractFactory("MPBV2");

    EIP5058Bound = await EIP5058BoundFactory.deploy();
    await Factory.boundDeploy(EIP5058Bound.address);

    await EIP5058Bound.setFactory(Factory.address);

    NFTBound = await ethers.getContractAt("ERC721Bound", await Factory.boundOf(EIP5058Bound.address));
  });

  it("Deployment should assign the total supply of tokens to the owner", async function() {
    const ownerBalance = await EIP5058Bound.balanceOf(owner.address);
    expect(await EIP5058Bound.totalSupply()).to.equal(ownerBalance);
  });

  it("lockMint works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058Bound.lockMint(alice.address, NFTId, timestamp + 2, "0x");

    expect(await EIP5058Bound.isLocked(NFTId)).eq(true);
    expect(await EIP5058Bound.lockerOf(NFTId)).eq(owner.address);
    expect(await EIP5058Bound.lockerOf(NFTId)).eq(owner.address);
    expect(await EIP5058Bound.tokenURI(NFTId)).eq(await NFTBound.tokenURI(NFTId));
  });

  it("Can not transfer when token is locked", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058Bound.lockMint(owner.address, NFTId, timestamp + 3, "0x");

    // can not transfer when token is locked
    await expect(EIP5058Bound.transferFrom(owner.address, alice.address, NFTId)).to.be.revertedWith(
      "ERC5058: token transfer while locked",
    );

    // can transfer when token is unlocked
    await ethers.provider.send("evm_mine", []);
    await EIP5058Bound.transferFrom(owner.address, alice.address, NFTId);
    expect(await EIP5058Bound.ownerOf(NFTId)).eq(alice.address);
  });

  it("isLocked works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058Bound.lockMint(owner.address, NFTId, timestamp + 2, "0x");

    // isLocked works
    expect(await EIP5058Bound.isLocked(NFTId)).eq(true);
    await ethers.provider.send("evm_mine", []);
    expect(await EIP5058Bound.isLocked(NFTId)).eq(false);
  });

  it("lockFrom works", async function() {
    const NFTId = 0;
    let block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058Bound.lockMint(owner.address, NFTId, timestamp + 3, "0x");

    await expect(EIP5058Bound.lockFrom(owner.address, NFTId, timestamp + 5)).to.be.revertedWith(
      "ERC5058: token is locked",
    );

    await ethers.provider.send("evm_mine", []);
    await EIP5058Bound.lockFrom(owner.address, NFTId, timestamp + 5);
  });

  it("unlockFrom works with lockMint", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber()
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058Bound.lockMint(owner.address, NFTId, timestamp + 3, "0x");

    // unlock works
    expect(await EIP5058Bound.isLocked(NFTId)).eq(true);
    expect(await EIP5058Bound.lockerOf(NFTId)).eq(owner.address);
    await EIP5058Bound.unlockFrom(owner.address, NFTId);
    expect(await EIP5058Bound.isLocked(NFTId)).eq(false);
  });

  it("unlockFrom works", async function() {
    const NFTId = 0;

    await EIP5058Bound.mint(owner.address, NFTId);

    await expect(EIP5058Bound.unlockFrom(owner.address, NFTId)).to.be.revertedWith(
      "ERC5058: locker query for non-locked token",
    );
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058Bound.lockFrom(owner.address, NFTId, timestamp + 3);
    expect(await EIP5058Bound.isLocked(NFTId)).eq(true);
    await EIP5058Bound.unlockFrom(owner.address, NFTId);
    expect(await EIP5058Bound.isLocked(NFTId)).eq(false);
  });

  it("lockApprove works", async function() {
    const NFTId = 0;
    await EIP5058Bound.mint(alice.address, NFTId);

    let block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await expect(EIP5058Bound.lockFrom(owner.address, NFTId, timestamp + 2)).to.be.revertedWith(
      "ERC5058: lock caller is not owner nor approved",
    );

    await EIP5058Bound.connect(alice).lockApprove(owner.address, NFTId);
    expect(await EIP5058Bound.getLockApproved(NFTId)).eq(owner.address);

    await expect(EIP5058Bound.lockFrom(owner.address, NFTId, timestamp + 4)).to.be.revertedWith(
      "ERC5058: lock from incorrect owner",
    );
    await EIP5058Bound.lockFrom(alice.address, NFTId, timestamp + 6);
    expect(await EIP5058Bound.isLocked(NFTId)).eq(true);

    await expect(EIP5058Bound.lockApprove(alice.address, NFTId)).to.be.revertedWith(
      "ERC5058: token is locked",
    );
  });

  it("setLockApproveForAll works", async function() {
    const NFTId = 0;

    await EIP5058Bound.mint(alice.address, NFTId);
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await expect(EIP5058Bound.lockFrom(alice.address, NFTId, timestamp + 2)).to.be.revertedWith(
      "ERC5058: lock caller is not owner nor approved",
    );

    await EIP5058Bound.connect(alice).setLockApprovalForAll(owner.address, true);
    expect(await EIP5058Bound.isLockApprovedForAll(alice.address, owner.address)).eq(true);

    await EIP5058Bound.lockFrom(alice.address, NFTId, timestamp + 6);

    await EIP5058Bound.connect(alice).setLockApprovalForAll(owner.address, false);
    expect(await EIP5058Bound.isLockApprovedForAll(alice.address, owner.address)).eq(false);
  });

  it("burn works", async function() {
    const NFTId = 0;

    await EIP5058Bound.mint(owner.address, NFTId);
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058Bound.lockFrom(owner.address, NFTId, timestamp + 2);

    await ethers.provider.send("evm_mine", []);
    expect(await NFTBound.exists(NFTId)).eq(true);
    await EIP5058Bound.burn( NFTId);
    expect(await NFTBound.exists(NFTId)).eq(false);
  });

  it("mintBatch works", async () => {
    const tokenIds= [100, 101, 203]
    await EIP5058Bound.mintBatch(alice.address, tokenIds)
    for (const tokenId of tokenIds) {
      expect(await EIP5058Bound.ownerOf(tokenId)).eq(alice.address);
      expect(await EIP5058Bound.exists(tokenId)).eq(true);
    }
  });

  it("mintRange works", async () => {
    let formTokenId = 200
    const toTokenId = 205
    await EIP5058Bound.mintRange(alice.address, formTokenId, toTokenId)
    for  (; formTokenId <= toTokenId; formTokenId++) {
      expect(await EIP5058Bound.ownerOf(formTokenId)).eq(alice.address);
      expect(await EIP5058Bound.exists(formTokenId)).eq(true);
    }
  });
});
