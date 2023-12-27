const { ethers, upgrades } = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();

  const FiboScriptions = await ethers.getContractFactory("FiboScriptions");
  const fiboScriptions = await upgrades.deployProxy(FiboScriptions);
  await fiboScriptions.waitForDeployment();
  console.log(`Fibo Scriptions deployed to ${fiboScriptions.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
