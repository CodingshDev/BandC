usePlugin("@nomiclabs/buidler-truffle5");
usePlugin("@nomiclabs/buidler-web3");

// This is a sample Buidler task. To learn how to create your own go to
// https://buidler.dev/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.getAddress());
  }
});

// You have to export an object to set up your config
// This object can have the following optional entries:
// defaultNetwork, networks, solc, and paths.
// Go to https://buidler.dev/config/ to learn more
module.exports = {
  defaultNetwork: "localhost",
  networks: {
    buidlerevm: { allowUnlimitedContractSize: true },
    localhost: { url: "http://localhost:8545" },
  },
  // This is a sample solc configuration that specifies which version of solc to use
  solc: {
    version: "0.5.16",
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    artifacts: "./build/contracts",
  },
};
