const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FiboScriptions", function () {
  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();

    const FiboScriptions = await ethers.getContractFactory("FiboScriptions");
    const fiboscriptions = await upgrades.deployProxy(FiboScriptions);
    await fiboscriptions.waitForDeployment();

    const FIBOsExchange = await ethers.deployContract("FIBOsExchange", [fiboscriptions.target]);
    await FIBOsExchange.waitForDeployment();

    const stakePool = await ethers.deployContract("FIBOsExchange", [fiboscriptions.target]);
    await stakePool.waitForDeployment();

    await fiboscriptions.setStakingPoolAddr(stakePool.target);
    await fiboscriptions.setFibosExchange(FIBOsExchange.target);

    return {
      owner,
      user1,
      user2,
      stakePool,
      fiboscriptions,
      FIBOsExchange,
    }

  }

  describe('inscriptions', function () { 
    it("Inscriptions should be intact", async function () {
      const { owner, user1, user2, fiboscriptions, stakePool} = await loadFixture(deployFixture);

      expect(await fiboscriptions.name()).to.equal("FiboScriptions");
      expect(await fiboscriptions.symbol()).to.equal("FIBOs");
      expect(await fiboscriptions.decimals()).to.equal(0);

      const tx = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx.wait();

      expect(await ethers.provider.getBalance(stakePool.target)).to.equal(ethers.parseEther("10"));
      expect(await fiboscriptions.balanceOf(owner.address)).to.equal(777);

      await expect(owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("1"),
      })).to.be.revertedWithCustomError(
        fiboscriptions,
        "InvalidAmount"
      ).withArgs(ethers.parseEther("1"));

    })

    it("Test transfer function.", async function () {
      const { owner, user1, user2, fiboscriptions} = await loadFixture(deployFixture);
      const tx = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx.wait();

      expect(await fiboscriptions.lastFibos()).to.equal(0);
      expect(await fiboscriptions.ownerFibos(owner.address)).to.deep.equal([0]);

      await fiboscriptions.transfer(user1.address, 777);
      expect (await fiboscriptions.balanceOf(user1.address)).to.equal(777);
      expect (await fiboscriptions.balanceOf(owner.address)).to.equal(0);
      expect (await fiboscriptions.getOwnerFibosLength(user1.address)).to.equal(1);
      expect (await fiboscriptions.getOwnerFibosLength(owner.address)).to.equal(0);

      expect(await fiboscriptions.ownerFibos(owner.address)).to.deep.equal([]);
      expect(await fiboscriptions.ownerFibos(user1.address)).to.deep.equal([1]);

      expect(await fiboscriptions.lastFibos()).to.equal(1);

      const tx2 = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx2.wait();

      expect(await fiboscriptions.ownerFibos(owner.address)).to.deep.equal([2]);

      await fiboscriptions.transfer(user2.address, 300);
      expect (await fiboscriptions.balanceOf(user2.address)).to.equal(300);
      expect (await fiboscriptions.balanceOf(owner.address)).to.equal(477);
      expect (await fiboscriptions.getOwnerFibosLength(user2.address)).to.equal(1);
      expect (await fiboscriptions.getOwnerFibosLength(owner.address)).to.equal(1);

      expect(await fiboscriptions.ownerFibos(owner.address)).to.deep.equal([3]);
      expect(await fiboscriptions.ownerFibos(user2.address)).to.deep.equal([4]);

      expect (await fiboscriptions.getHoldersCount()).to.equal(3);

      expect (await fiboscriptions.totalSupply()).to.equal(300 + 777 + 477);

      expect (await fiboscriptions.getFibosTotalValue([1])).to.equal(777);
      expect (await fiboscriptions.getFibosTotalValue([3,4])).to.equal(300 + 477);

      expect (await fiboscriptions.getStake(owner.address)).to.equal(ethers.parseEther("20"));

      expect (await fiboscriptions.getOwner(1)).to.equal(user1.address);
      expect (await fiboscriptions.getOwner(3)).to.equal(owner.address);
      expect (await fiboscriptions.getOwner(4)).to.equal(user2.address);

      await fiboscriptions.connect(user1).transferFibos(user2.address, [1]);
      expect(await fiboscriptions.ownerFibos(user1.address)).to.deep.equal([]);
      expect(await fiboscriptions.balanceOf(user1.address)).to.equal(0);
      expect(await fiboscriptions.ownerFibos(user2.address)).to.deep.equal([4, 1]);
      expect(await fiboscriptions.balanceOf(user2.address)).to.equal(300 + 777);

    })

    it("Approve should be intact.", async () => {
      const {owner, user1, user2, fiboscriptions} = await loadFixture(deployFixture);
      const tx = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx.wait();

      await fiboscriptions.approve(user1.address, 100);
      await expect(fiboscriptions.connect(user1).transferFrom(owner.address, user2.address, 777)).to.be.revertedWithCustomError(
        fiboscriptions,
        "InsufficientAllowance" 
      ).withArgs(user1.address, 100, 777); 

      await fiboscriptions.approve(user1.address, 777);
      await fiboscriptions.connect(user1).transferFrom(owner.address, user2.address, 777);

      expect(await fiboscriptions.ownerFibos(user2.address)).to.deep.equal([1]);
      expect(await fiboscriptions.balanceOf(user2.address)).to.equal(777);

      expect(await fiboscriptions.ownerFibos(owner.address)).to.deep.equal([]);
      expect(await fiboscriptions.balanceOf(owner.address)).to.equal(0);

      const tx2 = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx2.wait();
      const tx3 = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx3.wait(); 

      await fiboscriptions.approve(user1.address, 2000);
      await fiboscriptions.connect(user1).transferFromFibos(owner.address, user1.address, [2, 3]);

      expect(await fiboscriptions.ownerFibos(user1.address)).to.deep.equal([2, 3]);
      expect(await fiboscriptions.balanceOf(user1.address)).to.equal(777 + 777);
      expect(await fiboscriptions.allowance(owner.address, user1.address)).to.equal(2000 - 777 - 777);
    })

    it("Test exchange-only call.", async () => {
      const {owner, user1, user2, fiboscriptions, FIBOsExchange} = await loadFixture(deployFixture);
        const tx = await owner.sendTransaction({
          to: fiboscriptions.target,
          value: ethers.parseEther("10"),
        });
        await tx.wait();
      await FIBOsExchange.listFibos(0, 4101437311, 100);

      const tx2 = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx2.wait();

      await expect(fiboscriptions.transfer(user1.address, 1000)).to.be.revertedWithCustomError(
        fiboscriptions,
        "InsufficientBalance"
      ).withArgs(owner.address, 777, 1000);

      await expect(fiboscriptions.transferFibos(user1.address, [0])).to.be.revertedWithCustomError(
        fiboscriptions,
        "LockedFibos"
      ).withArgs(0);

    })

    it("Test remaining errors.", async () => {
      const {owner, user1, user2, fiboscriptions} = await loadFixture(deployFixture);
      const zeroAddress = "0x0000000000000000000000000000000000000000";
      const tx = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx.wait();

      await expect(fiboscriptions.transferFibos(user1.address, [1])).to.be.revertedWithCustomError(
        fiboscriptions,
        "NotOwner" 
      ).withArgs(owner.address, 1, zeroAddress); 

      await expect(fiboscriptions.transferFibos(zeroAddress, [1])).to.be.revertedWithCustomError(
        fiboscriptions,
        "InvalidReceiver"
      ).withArgs(zeroAddress);

      await expect(fiboscriptions.transfer(zeroAddress, 100)).to.be.revertedWithCustomError(
        fiboscriptions,
        "InvalidReceiver"
      ).withArgs(zeroAddress);

      await expect(fiboscriptions.approve(zeroAddress, 100)).to.be.revertedWithCustomError(
        fiboscriptions,
        "InvalidSpender"
      ).withArgs(zeroAddress);

      await expect(fiboscriptions.transfer(user1.address, 1000)).to.be.revertedWithCustomError(
        fiboscriptions,
        "InsufficientBalance"
      ).withArgs(owner.address, 777, 1000);

      await expect(fiboscriptions.getOwner(100)).to.be.revertedWithCustomError(
        fiboscriptions,
        "NonexistentFibos"
      ).withArgs(100);

    })

    it("Test error when max circulation reached, preventing further inscriptions.", async () => {
      const {owner, user1, user2, fiboscriptions} = await loadFixture(deployFixture);
      const tx = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx.wait();

      const storageSlotIndex = "0xff";
  
      await network.provider.send("hardhat_setStorageAt", [
        fiboscriptions.target,
        storageSlotIndex,
        "0x0000000000000000000000000000000000000000000000000000000004a19ba0", // 77700000
      ]);

      await expect(owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      })).to.be.revertedWithCustomError(
        fiboscriptions,
        "MaxSupplyReached"
      ).withArgs();
      
    })

    it("Test fetching all holder addresses.", async () => {
      const {owner, user1, user2, fiboscriptions} = await loadFixture(deployFixture);
      const tx = await owner.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx.wait();
      const tx2 = await user1.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx2.wait();
      const tx3 = await user2.sendTransaction({
        to: fiboscriptions.target,
        value: ethers.parseEther("10"),
      });
      await tx3.wait();

      expect (await fiboscriptions.getHoldersAddress()).to.deep.equal([owner.address, user1.address, user2.address]);
    })
  
  })

});
