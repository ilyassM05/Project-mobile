# Blockchain Setup Guide

## Overview

This guide covers setting up the Ethereum blockchain integration for the e-learning platform, including:
- Setting up Hardhat for smart contract development
- Writing and deploying smart contracts
- Configuring RPC provider (Infura/Alchemy)
- Integrating blockchain with Flutter

---

## Step 1: Install Node.js and npm

**Prerequisites:**
- Node.js 16+ and npm

**Verify installation:**
```bash
node --version
npm --version
```

---

## Step 2: Create Hardhat Project

### Initialize Project

```bash
mkdir blockchain
cd blockchain
npm init -y
```

### Install Hardhat and Dependencies

```bash
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts dotenv
npx hardhat init
```

Select: **Create a JavaScript project**

### Project Structure

```
blockchain/
├── contracts/
│   ├── CoursePayment.sol
│   └── CourseCertificate.sol
├── scripts/
│   └── deploy.js
├── test/
│   ├── CoursePayment.test.js
│   └── CourseCertificate.test.js
├── hardhat.config.js
├── .env
└── package.json
```

---

## Step 3: Set Up RPC Provider

### Option A: Infura

1. Go to [Infura.io](https://infura.io)
2. Sign up for free account
3. Create new project
4. Select "Ethereum" → "Web3 API"
5. Copy the Sepolia endpoint URL

**Example:**
```
https://sepolia.infura.io/v3/YOUR_API_KEY
```

### Option B: Alchemy

1. Go to [Alchemy.com](https://alchemy.com)
2. Sign up for free account
3. Create new app
4. Select "Ethereum" → "Sepolia"
5. Copy the HTTPS endpoint

**Example:**
```
https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

---

## Step 4: Configure Environment Variables

Create `.env` file in `blockchain/` directory:

```bash
# .env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_API_KEY
PRIVATE_KEY=your_wallet_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key (optional)
```

**⚠️ IMPORTANT:** Add `.env` to `.gitignore`!

```bash
echo ".env" >> .gitignore
```

---

## Step 5: Configure Hardhat

Edit `hardhat.config.js`:

```javascript
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
```

---

## Step 6: Write Smart Contracts

### Contract 1: CoursePayment.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CoursePayment {
    struct Purchase {
        address student;
        string courseId;
        uint256 amount;
        uint256 timestamp;
    }
    
    mapping(address => Purchase[]) public userPurchases;
    mapping(string => uint256) public coursePrices;
    mapping(string => address) public courseInstructors;
    
    event CoursePurchased(
        address indexed student, 
        string courseId, 
        uint256 amount,
        uint256 timestamp
    );
    
    event CoursePriceSet(
        string courseId,
        uint256 price,
        address instructor
    );
    
    function setCoursePrice(
        string memory courseId, 
        uint256 priceInWei
    ) public {
        coursePrices[courseId] = priceInWei;
        courseInstructors[courseId] = msg.sender;
        
        emit CoursePriceSet(courseId, priceInWei, msg.sender);
    }
    
    function buyCourse(string memory courseId) public payable {
        require(coursePrices[courseId] > 0, "Course does not exist");
        require(msg.value >= coursePrices[courseId], "Insufficient payment");
        
        Purchase memory newPurchase = Purchase({
            student: msg.sender,
            courseId: courseId,
            amount: msg.value,
            timestamp: block.timestamp
        });
        
        userPurchases[msg.sender].push(newPurchase);
        
        // Transfer payment to instructor
        address instructor = courseInstructors[courseId];
        if (instructor != address(0)) {
            payable(instructor).transfer(msg.value);
        }
        
        emit CoursePurchased(msg.sender, courseId, msg.value, block.timestamp);
    }
    
    function getUserPurchases(address student) 
        public 
        view 
        returns (Purchase[] memory) 
    {
        return userPurchases[student];
    }
    
    function hasPurchased(address student, string memory courseId) 
        public 
        view 
        returns (bool) 
    {
        Purchase[] memory purchases = userPurchases[student];
        for (uint i = 0; i < purchases.length; i++) {
            if (keccak256(bytes(purchases[i].courseId)) == keccak256(bytes(courseId))) {
                return true;
            }
        }
        return false;
    }
}
```

### Contract 2: CourseCertificate.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CourseCertificate is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    struct Certificate {
        uint256 tokenId;
        address student;
        string courseId;
        string courseName;
        uint256 completionDate;
        bool exists;
    }
    
    mapping(uint256 => Certificate) public certificates;
    mapping(address => uint256[]) public studentCertificates;
    
    event CertificateMinted(
        uint256 indexed tokenId,
        address indexed student,
        string courseId,
        string courseName,
        uint256 completionDate
    );
    
    constructor() ERC721("CourseCertificate", "CERT") {}
    
    function mintCertificate(
        address student,
        string memory courseId,
        string memory courseName
    ) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _mint(student, newTokenId);
        
        Certificate memory newCert = Certificate({
            tokenId: newTokenId,
            student: student,
            courseId: courseId,
            courseName: courseName,
            completionDate: block.timestamp,
            exists: true
        });
        
        certificates[newTokenId] = newCert;
        studentCertificates[student].push(newTokenId);
        
        emit CertificateMinted(
            newTokenId, 
            student, 
            courseId, 
            courseName, 
            block.timestamp
        );
        
        return newTokenId;
    }
    
    function getCertificate(uint256 tokenId) 
        public 
        view 
        returns (Certificate memory) 
    {
        require(certificates[tokenId].exists, "Certificate does not exist");
        return certificates[tokenId];
    }
    
    function getStudentCertificates(address student) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return studentCertificates[student];
    }
    
    function verifyCertificate(uint256 tokenId) 
        public 
        view 
        returns (bool, address, string memory) 
    {
        if (!certificates[tokenId].exists) {
            return (false, address(0), "");
        }
        
        Certificate memory cert = certificates[tokenId];
        return (true, cert.student, cert.courseName);
    }
}
```

---

## Step 7: Write Tests

### Test CoursePayment.sol

```javascript
// test/CoursePayment.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CoursePayment", function () {
  let coursePayment;
  let owner, student, instructor;

  beforeEach(async function () {
    [owner, student, instructor] = await ethers.getSigners();
    const CoursePayment = await ethers.getContractFactory("CoursePayment");
    coursePayment = await CoursePayment.deploy();
  });

  it("Should set course price", async function () {
    await coursePayment.connect(instructor).setCoursePrice(
      "course1", 
      ethers.parseEther("0.01")
    );
    
    const price = await coursePayment.coursePrices("course1");
    expect(price).to.equal(ethers.parseEther("0.01"));
  });

  it("Should allow purchasing a course", async function () {
    await coursePayment.connect(instructor).setCoursePrice(
      "course1",
      ethers.parseEther("0.01")
    );
    
    await coursePayment.connect(student).buyCourse("course1", {
      value: ethers.parseEther("0.01")
    });
    
    const hasPurchased = await coursePayment.hasPurchased(
      student.address,
      "course1"
    );
    expect(hasPurchased).to.be.true;
  });
});
```

Run tests:
```bash
npx hardhat test
```

---

## Step 8: Deploy Contracts

### Create Deploy Script

```javascript
// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  console.log("Deploying contracts to Sepolia...");
  
  // Deploy CoursePayment
  const CoursePayment = await hre.ethers.getContractFactory("CoursePayment");
  const coursePayment = await CoursePayment.deploy();
  await coursePayment.waitForDeployment();
  const coursePaymentAddress = await coursePayment.getAddress();
  console.log("CoursePayment deployed to:", coursePaymentAddress);
  
  // Deploy CourseCertificate
  const CourseCertificate = await hre.ethers.getContractFactory("CourseCertificate");
  const courseCertificate = await CourseCertificate.deploy();
  await courseCertificate.waitForDeployment();
  const courseCertificateAddress = await courseCertificate.getAddress();
  console.log("CourseCertificate deployed to:", courseCertificateAddress);
  
  // Save addresses
  const fs = require('fs');
  const addresses = {
    coursePayment: coursePaymentAddress,
    courseCertificate: courseCertificateAddress,
    network: "sepolia"
  };
  
  fs.writeFileSync(
    'deployed-addresses.json',
    JSON.stringify(addresses, null, 2)
  );
  
  console.log("\nDeployment complete!");
  console.log("Contract addresses saved to deployed-addresses.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

### Deploy to Sepolia

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

**Save the deployed contract addresses!** You'll need them in Flutter.

---

## Step 9: Get Testnet ETH

1. Get a wallet address (from MetaMask or generate one)
2. Visit [Sepolia Faucet](https://sepoliafaucet.com/)
3. Enter your wallet address
4. Request test ETH
5. Wait for confirmation (~30 seconds)

---

## Step 10: Verify Contracts on Etherscan (Optional)

```bash
npx hardhat verify --network sepolia CONTRACT_ADDRESS
```

---

## Flutter Integration

### Install web3dart

```bash
flutter pub add web3dart http
```

### Create Blockchain Service

See `implementation_plan.md` for detailed Flutter integration code.

---

## Verification Checklist

- [ ] Hardhat project created
- [ ] RPC provider configured (Infura/Alchemy)
- [ ] Environment variables set up
- [ ] Smart contracts written
- [ ] Tests passing
- [ ] Contracts deployed to Sepolia
- [ ] Contract addresses saved
- [ ] Test ETH obtained

---

## Troubleshooting

### Deployment Fails
- Check RPC URL is correct
- Verify private key has test ETH
- Check network configuration

### "Insufficient Funds" Error
- Get test ETH from Sepolia faucet
- Wait for transaction confirmation

### RPC Provider Rate Limit
- Check your plan limits
- Consider upgrading or using multiple providers

---

## Next Steps

1. Copy deployed contract addresses
2. Integrate with Flutter using web3dart
3. Test transactions from mobile app
4. Implement certificate minting
