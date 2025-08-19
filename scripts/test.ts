import { ethers } from "ethers";

async function testConnection() {
  try {
    console.log("Testing ethers connection...");

    // 测试 provider 连接
    const provider = new ethers.JsonRpcProvider("http://localhost:8545");
    const network = await provider.getNetwork();
    console.log("Connected to network:", network.name);

    // 测试钱包创建
    const wallet = ethers.Wallet.createRandom();
    console.log("Test wallet created:", wallet.address);

    console.log("✅ Ethers 6 connection test passed!");
  } catch (error) {
    console.error("❌ Test failed:", error);
  }
}

testConnection();
