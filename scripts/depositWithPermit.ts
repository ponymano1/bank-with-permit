import { ethers } from "ethers";
import * as dotenv from "dotenv";

// 加载环境变量
dotenv.config();

// ERC20Permit 接口 ABI (只包含 permit 方法)
const ERC20_PERMIT_ABI = [
  "function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)",
  "function nonces(address owner) view returns (uint256)",
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function balanceOf(address account) view returns (uint256)",
  "function approve(address spender, uint256 amount) returns (bool)",
  "function transfer(address to, uint256 amount) returns (bool)",
  "function transferFrom(address from, address to, uint256 amount) returns (bool)",
];

// Bank 合约 ABI (只包含 depositWithPermit 方法)
const BANK_ABI = [
  "function depositWithPermit(address token, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)",
  "function getBalance(address user, address token) view returns (uint256)",
  "function supportedTokens(address token) view returns (bool)",
];

// EIP-712 域分隔符类型
const EIP712_DOMAIN = {
  name: "EIP712Domain",
  version: "1",
  chainId: 1,
  verifyingContract: "",
};

// Permit 类型
const PERMIT_TYPE = {
  name: "Permit",
  type: "Permit",
  fields: [
    { name: "owner", type: "address" },
    { name: "spender", type: "address" },
    { name: "value", type: "uint256" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
};

interface DepositConfig {
  rpcUrl: string;
  privateKey: string;
  bankAddress: string;
  tokenAddress: string;
  amount: string;
  deadline?: number;
}

class DepositWithPermit {
  private provider: ethers.JsonRpcProvider;
  private wallet: ethers.Wallet;
  private bankContract: ethers.Contract;
  private tokenContract: ethers.Contract;

  constructor(config: DepositConfig) {
    this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
    this.wallet = new ethers.Wallet(config.privateKey, this.provider);
    this.bankContract = new ethers.Contract(
      config.bankAddress,
      BANK_ABI,
      this.wallet
    );
    this.tokenContract = new ethers.Contract(
      config.tokenAddress,
      ERC20_PERMIT_ABI,
      this.wallet
    );
  }

  /**
   * 获取当前时间戳
   */
  private getCurrentTimestamp(): number {
    return Math.floor(Date.now() / 1000);
  }

  /**
   * 获取代币信息
   */
  async getTokenInfo() {
    try {
      const [name, symbol, decimals] = await Promise.all([
        this.tokenContract.name(),
        this.tokenContract.symbol(),
        this.tokenContract.decimals(),
      ]);

      console.log(`Token Info:`);
      console.log(`  Name: ${name}`);
      console.log(`  Symbol: ${symbol}`);
      console.log(`  Decimals: ${decimals}`);

      return { name, symbol, decimals };
    } catch (error) {
      console.error("Error getting token info:", error);
      throw error;
    }
  }

  /**
   * 检查代币是否被Bank支持
   */
  async checkTokenSupport(): Promise<boolean> {
    try {
      const isSupported = await this.bankContract.supportedTokens(
        this.tokenContract.target
      );
      console.log(`Token supported by Bank: ${isSupported}`);
      return isSupported;
    } catch (error) {
      console.error("Error checking token support:", error);
      throw error;
    }
  }

  /**
   * 获取用户当前余额
   */
  async getCurrentBalance(): Promise<bigint> {
    try {
      const balance = await this.bankContract.getBalance(
        this.wallet.address,
        this.tokenContract.target
      );
      console.log(
        `Current balance in Bank: ${ethers.formatEther(balance)} tokens`
      );
      return balance;
    } catch (error) {
      console.error("Error getting current balance:", error);
      throw error;
    }
  }

  /**
   * 创建 EIP-712 签名
   */
  async createPermitSignature(
    amount: bigint,
    deadline: number
  ): Promise<ethers.Signature> {
    try {
      // 获取当前 nonce
      const nonce = await this.tokenContract.nonces(this.wallet.address);
      console.log(`Current nonce: ${nonce}`);

      // 获取代币信息用于域名分隔符
      const tokenInfo = await this.getTokenInfo();

      // 创建域名分隔符
      const domain = {
        name: tokenInfo.name,
        version: "1",
        chainId: await this.provider
          .getNetwork()
          .then((net) => Number(net.chainId)),
        verifyingContract: this.tokenContract.target.toString(),
      };

      // 创建要签名的数据
      const message = {
        owner: this.wallet.address,
        spender: this.bankContract.target,
        value: amount,
        nonce: nonce,
        deadline: deadline,
      };

      // 创建 EIP-712 签名
      const signature = await this.wallet.signTypedData(
        domain,
        {
          Permit: [
            { name: "owner", type: "address" },
            { name: "spender", type: "address" },
            { name: "value", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" },
          ],
        },
        message
      );

      console.log(`Permit signature created: ${signature}`);

      // 解析签名
      const sig = ethers.Signature.from(signature);
      console.log(`Signature components:`);
      console.log(`  v: ${sig.v}`);
      console.log(`  r: ${sig.r}`);
      console.log(`  s: ${sig.s}`);

      return sig;
    } catch (error) {
      console.error("Error creating permit signature:", error);
      throw error;
    }
  }

  /**
   * 执行 depositWithPermit
   */
  async depositWithPermit(amount: string, deadline?: number): Promise<void> {
    try {
      console.log(`\n=== Starting Deposit with Permit ===`);
      console.log(`Bank Address: ${this.bankContract.target}`);
      console.log(`Token Address: ${this.tokenContract.target}`);
      console.log(`User Address: ${this.wallet.address}`);
      console.log(`Amount: ${amount} tokens`);

      // 检查代币是否被支持
      const isSupported = await this.checkTokenSupport();
      if (!isSupported) {
        throw new Error("Token is not supported by Bank contract");
      }

      // 获取当前余额
      const currentBalance = await this.getCurrentBalance();

      // 设置截止时间 (默认20分钟后)
      const finalDeadline = deadline || this.getCurrentTimestamp() + 20 * 60;
      console.log(`Deadline: ${new Date(finalDeadline * 1000).toISOString()}`);

      // 转换金额为 wei
      const tokenInfo = await this.getTokenInfo();
      const amountWei = ethers.parseUnits(amount, tokenInfo.decimals);
      console.log(`Amount in wei: ${amountWei}`);

      // 创建 permit 签名
      const signature = await this.createPermitSignature(
        amountWei,
        finalDeadline
      );

      // 执行 depositWithPermit
      console.log(`\nExecuting depositWithPermit...`);
      const tx = await this.bankContract.depositWithPermit(
        this.tokenContract.target,
        amountWei,
        finalDeadline,
        signature.v,
        signature.r,
        signature.s
      );

      console.log(`Transaction hash: ${tx.hash}`);
      console.log(`Waiting for confirmation...`);

      // 等待交易确认
      const receipt = await tx.wait();
      console.log(`Transaction confirmed in block: ${receipt?.blockNumber}`);

      // 获取新的余额
      const newBalance = await this.getCurrentBalance();
      const deposited = newBalance - currentBalance;
      console.log(`Deposited: ${ethers.formatEther(deposited)} tokens`);

      console.log(`\n=== Deposit with Permit Completed Successfully ===`);
    } catch (error) {
      console.error("Error in depositWithPermit:", error);
      throw error;
    }
  }
}

// 主函数
async function main() {
  try {
    // 从环境变量获取配置
    const config: DepositConfig = {
      rpcUrl: process.env.RPC_URL || "http://localhost:8545",
      privateKey: process.env.PRIVATE_KEY!,
      bankAddress: process.env.BANK_ADDRESS!,
      tokenAddress: process.env.TOKEN_ADDRESS!,
      amount: process.env.AMOUNT || "10", // 默认10个代币
      deadline: process.env.DEADLINE
        ? parseInt(process.env.DEADLINE)
        : undefined,
    };

    // 验证必要的环境变量
    if (!config.privateKey) {
      throw new Error("PRIVATE_KEY environment variable is required");
    }
    if (!config.bankAddress) {
      throw new Error("BANK_ADDRESS environment variable is required");
    }
    if (!config.tokenAddress) {
      throw new Error("TOKEN_ADDRESS environment variable is required");
    }

    console.log("Configuration:");
    console.log(`  RPC URL: ${config.rpcUrl}`);
    console.log(`  Bank Address: ${config.bankAddress}`);
    console.log(`  Token Address: ${config.tokenAddress}`);
    console.log(`  Amount: ${config.amount} tokens`);

    // 创建 DepositWithPermit 实例
    const depositWithPermit = new DepositWithPermit(config);

    // 执行存款
    await depositWithPermit.depositWithPermit(config.amount, config.deadline);
  } catch (error) {
    console.error("Script failed:", error);
    process.exit(1);
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  main();
}

export { DepositWithPermit, DepositConfig };
