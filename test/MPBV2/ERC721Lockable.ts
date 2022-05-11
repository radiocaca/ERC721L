import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MPBV2 } from "typechain-types";

describe("MPB ERC721Lockable contract", function() {
  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let EIP5058: MPBV2;
  
  beforeEach(async () => {
    [owner, alice] = await ethers.getSigners();
    
    const ERC5058Factory = await ethers.getContractFactory("MPBV2");
    
    EIP5058 = await ERC5058Factory.deploy();
  });
  
  it("Deployment should assign the total supply of tokens to the owner", async function() {
    const ownerBalance = await EIP5058.balanceOf(owner.address);
    expect(await EIP5058.totalSupply()).to.equal(ownerBalance);
  });
  
  it("lockMint works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    await EIP5058.lockMint(alice.address, NFTId, block + 2, "0x");
    
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    expect(await EIP5058.lockerOf(NFTId)).eq(owner.address);
  });
  
  it("Can not transfer when token is locked", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    await EIP5058.lockMint(owner.address, NFTId, block + 3, "0x");
    
    // can not transfer when token is locked
    await expect(EIP5058.transferFrom(owner.address, alice.address, NFTId)).to.be.revertedWith(
      "ERC5058: token transfer while locked",
    );
    
    // can transfer when token is unlocked
    await ethers.provider.send("evm_mine", []);
    await EIP5058.transferFrom(owner.address, alice.address, NFTId);
    expect(await EIP5058.ownerOf(NFTId)).eq(alice.address);
  });
  
  it("isLocked works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    await EIP5058.lockMint(owner.address, NFTId, block + 2, "0x");
    
    // isLocked works
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    await ethers.provider.send("evm_mine", []);
    expect(await EIP5058.isLocked(NFTId)).eq(false);
  });
  
  it("lockFrom works", async function() {
    const NFTId = 0;
    let block = await ethers.provider.getBlockNumber();
    await EIP5058.lockMint(owner.address, NFTId, block + 3, "0x");
    
    await expect(EIP5058.lockFrom(owner.address, NFTId, block + 5)).to.be.revertedWith(
      "ERC5058: token is locked",
    );
    
    await ethers.provider.send("evm_mine", []);
    await EIP5058.lockFrom(owner.address, NFTId, block + 5);
  });
  
  it("unlockFrom works with lockMint", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber()
    await EIP5058.lockMint(owner.address, NFTId, block + 3, "0x");
    
    // unlock works
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    expect(await EIP5058.lockerOf(NFTId)).eq(owner.address);
    await EIP5058.unlockFrom(owner.address, NFTId);
    expect(await EIP5058.isLocked(NFTId)).eq(false);
  });
  
  it("unlockFrom works", async function() {
    const NFTId = 0;
    
    await EIP5058.mint(owner.address, NFTId);

    await expect(EIP5058.unlockFrom(owner.address, NFTId)).to.be.revertedWith(
      "ERC5058: locker query for non-locked token",
    );
    const block = await ethers.provider.getBlockNumber();
    await EIP5058.lockFrom(owner.address, NFTId, block + 3);
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    await EIP5058.unlockFrom(owner.address, NFTId);
    expect(await EIP5058.isLocked(NFTId)).eq(false);
  });
  
  it("lockApprove works", async function() {
    const NFTId = 0;
    await EIP5058.mint(alice.address, NFTId);
  
    let block = await ethers.provider.getBlockNumber();
    await expect(EIP5058.lockFrom(owner.address, NFTId, block + 2)).to.be.revertedWith(
      "ERC5058: lock caller is not owner nor approved",
    );
    
    await EIP5058.connect(alice).lockApprove(owner.address, NFTId);
    expect(await EIP5058.getLockApproved(NFTId)).eq(owner.address);
  
    await expect(EIP5058.lockFrom(owner.address, NFTId, block + 4)).to.be.revertedWith(
      "ERC5058: lock from incorrect owner",
    );
    await EIP5058.lockFrom(alice.address, NFTId, block + 6);
    expect(await EIP5058.isLocked(NFTId)).eq(true);
  
    await expect(EIP5058.lockApprove(alice.address, NFTId)).to.be.revertedWith(
      "ERC5058: token is locked",
    );
  });
  
  it("setLockApproveForAll works", async function() {
    const NFTId = 0;
  
    await EIP5058.mint(alice.address, NFTId);
    const block = await ethers.provider.getBlockNumber();
    await expect(EIP5058.lockFrom(alice.address, NFTId, block + 2)).to.be.revertedWith(
      "ERC5058: lock caller is not owner nor approved",
    );

    await EIP5058.connect(alice).setLockApprovalForAll(owner.address, true);
    expect(await EIP5058.isLockApprovedForAll(alice.address, owner.address)).eq(true);

    await EIP5058.lockFrom(alice.address, NFTId, block + 6);

    await EIP5058.connect(alice).setLockApprovalForAll(owner.address, false);
    expect(await EIP5058.isLockApprovedForAll(alice.address, owner.address)).eq(false);
  });
});
