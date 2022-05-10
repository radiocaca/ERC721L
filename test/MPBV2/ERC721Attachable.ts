import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MPBV2 } from "typechain-types";

describe("MPB ERC721Attachable contract", function() {
  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let AttachableMaster: MPBV2;
  let AttachableSlave: MPBV2;
  
  beforeEach(async () => {
    [owner, alice] = await ethers.getSigners();
    
    const contract = await ethers.getContractFactory("MPBV2");
    AttachableMaster = await contract.deploy();
    
    AttachableSlave = await contract.deploy();
  });
  
  it("Deployment should assign the total supply of tokens to the owner", async function() {
    const ownerBalance = await AttachableMaster.balanceOf(owner.address);
    expect(await AttachableMaster.totalSupply()).to.equal(ownerBalance);
  });
  
  it("slaveMint works", async function() {
    const MasterId = 0;
    const SlaveId = 1;
    await expect(AttachableSlave.slaveMint(alice.address, SlaveId, AttachableMaster.address, MasterId)).to.be.revertedWith(
      "ERC721Attachable: slave to non boundERC721 receiver");
    
    await AttachableMaster.addCollection(AttachableSlave.address);
    await expect(AttachableSlave.slaveMint(alice.address, SlaveId, AttachableMaster.address, MasterId)).to.be.revertedWith(
      "ERC721: owner query for nonexistent token");
    await AttachableMaster.mint(owner.address, MasterId);
    await expect(AttachableSlave.slaveMint(alice.address, SlaveId, AttachableMaster.address, MasterId)).to.be.revertedWith(
      "ERC721Attachable: slave to incorrect owner");
    await AttachableSlave.slaveMint(owner.address, SlaveId, AttachableMaster.address, MasterId);
  
    expect(await AttachableMaster.allSlaveTokenLength(MasterId)).eq(1);
    expect(await AttachableSlave.isSlaveToken(SlaveId)).eq(true);
    expect(await AttachableSlave.masterOf(SlaveId)).eq(AttachableMaster.address);
    expect((await AttachableMaster.slaveTokenByIndex(MasterId, 0)).tokenId).eq(SlaveId);
  });
  
  it("Can not transfer for slave token", async function() {
    const MasterId = 0;
    const SlaveId = 1;
    await AttachableMaster.addCollection(AttachableSlave.address);
    await AttachableMaster.mint(alice.address, MasterId);
    await AttachableSlave.slaveMint(alice.address, SlaveId, AttachableMaster.address, MasterId);
    
    await expect(AttachableSlave.connect(alice).transferFrom(alice.address, owner.address, SlaveId)).to.be.revertedWith(
      "ERC721Attachable: slave token transfer not allowed");
    
    await AttachableSlave.addTransferApproval(alice.address);
    
    await AttachableSlave.connect(alice).transferFrom(alice.address, owner.address, SlaveId);
    
    expect(await AttachableSlave.ownerOf(SlaveId)).eq(owner.address);
  });
  
  it("Slave token can transfer for master token", async function() {
    const MasterId = 0;
    const SlaveId = 1;
    await AttachableMaster.addCollection(AttachableSlave.address);
    await AttachableMaster.mint(owner.address, MasterId);
    await AttachableSlave.slaveMint(owner.address, SlaveId, AttachableMaster.address, MasterId);
    
    await AttachableMaster.transferFrom(owner.address, alice.address, MasterId);
  
    expect(await AttachableMaster.ownerOf(MasterId)).eq(alice.address);
    expect(await AttachableSlave.ownerOf(SlaveId)).eq(alice.address);
  });

  it("burn slave works", async function() {
    const MasterId = 0;
    const SlaveId = 1;
    await AttachableMaster.addCollection(AttachableSlave.address);
    await AttachableMaster.mint(owner.address, MasterId);
    await AttachableSlave.slaveMint(owner.address, SlaveId, AttachableMaster.address, MasterId);
  
    expect(await AttachableMaster.allSlaveTokenLength(MasterId)).eq(1);
    await AttachableSlave.burn(SlaveId);
    expect(await AttachableMaster.allSlaveTokenLength(MasterId)).eq(0);
  
    await AttachableMaster.transferFrom(owner.address, alice.address, MasterId);
  });
  
  it("burn master works", async function() {
    const MasterId = 0;
    const SlaveId = 1;
    await AttachableMaster.addCollection(AttachableSlave.address);
    await AttachableMaster.mint(owner.address, MasterId);
    await AttachableSlave.slaveMint(owner.address, SlaveId, AttachableMaster.address, MasterId);
    
    expect(await AttachableMaster.allSlaveTokenLength(MasterId)).eq(1);
    await AttachableMaster.burn(MasterId);
    expect(await AttachableMaster.allSlaveTokenLength(MasterId)).eq(0);
    expect(await AttachableSlave.exists(SlaveId)).eq(false);
  });
});
