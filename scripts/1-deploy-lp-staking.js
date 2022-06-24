// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  var stakingStartDate = 1657411200; // 10/07/2022 00:00:00
  var stakingDeadlineDate = 1688947200; // 10/07/2023 00:00:00
  var vestingDuration = 60 * 60 * 24 * 30;
  var availableRewardsEachPeriod = 3125000 * 10 ** 16;

  // We get the contract to deploy
  const LpStaking = await hre.ethers.getContractFactory("LpStaking");
  const lpStaking = await LpStaking.deploy(stakingStartDate, stakingDeadlineDate, vestingDuration, availableRewardsEachPeriod);

  await lpStaking.deployed();

  console.log("Lp Staking deployed to:", lpStaking.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
