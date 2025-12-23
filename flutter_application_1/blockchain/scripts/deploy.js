const hre = require("hardhat");
const fs = require("fs");

async function main() {
    console.log("Deploying CourseMarketplace contract...");

    const CourseMarketplace = await hre.ethers.getContractFactory("CourseMarketplace");
    const marketplace = await CourseMarketplace.deploy();
    await marketplace.waitForDeployment();

    const contractAddress = await marketplace.getAddress();

    // Verify address is valid (42 chars with 0x)
    console.log("Contract Address:", contractAddress);
    console.log("Address Length:", contractAddress.length);

    // Save clean address to file (no newline)
    fs.writeFileSync("deployed_address.txt", contractAddress, { encoding: 'utf8' });

    // Also output for easy copy
    console.log("\n=== COPY THIS ADDRESS ===");
    console.log(contractAddress);
    console.log("=========================");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
