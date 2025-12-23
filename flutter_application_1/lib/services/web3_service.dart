// =============================================================================
// WEB3 SERVICE - Blockchain Integration for Flutter
// =============================================================================
// WHAT IS THIS FILE?
// This service connects our Flutter app to the Ethereum blockchain.
// It allows users to purchase courses using cryptocurrency (ETH).
//
// HOW BLOCKCHAIN WORKS IN THIS APP:
// 1. User connects their crypto wallet (private key)
// 2. When buying a course, app sends ETH to the smart contract
// 3. Smart contract transfers ETH to instructor
// 4. Purchase is recorded permanently on blockchain
//
// KEY CONCEPTS:
// - Web3: JavaScript library for interacting with Ethereum
// - web3dart: Dart port of Web3 for Flutter
// - Ganache: Local Ethereum blockchain for testing
// - Private Key: Secret password that controls your wallet
// - Transaction: Any operation on blockchain (costs "gas")
// =============================================================================

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Web3Service {
  // ---------------------------------------------------------------------------
  // VARIABLES
  // ---------------------------------------------------------------------------
  Web3Client? _client; // Connection to Ethereum network
  late String _rpcUrl; // URL of Ethereum node (Ganache)
  bool _isInitialized = false;

  Credentials? _credentials; // User's wallet (private key)
  EthereumAddress? _contractAddress; // Address of our smart contract
  DeployedContract? _contract; // The smart contract object

  // Secure storage for private key (encrypted on device)
  final _storage = const FlutterSecureStorage();

  // ---------------------------------------------------------------------------
  // SINGLETON PATTERN - Only one instance of Web3Service
  // ---------------------------------------------------------------------------
  // This ensures we don't create multiple blockchain connections
  static final Web3Service _instance = Web3Service._internal();
  factory Web3Service() => _instance;
  Web3Service._internal();

  // ---------------------------------------------------------------------------
  // GETTERS - Check connection status
  // ---------------------------------------------------------------------------
  bool get isConnected => _credentials != null; // Is wallet connected?
  bool get isInitialized => _isInitialized; // Is service ready?
  bool get isContractReady => _contract != null; // Is contract loaded?

  // Get current wallet address
  EthereumAddress? get currentAddress =>
      _credentials != null ? (_credentials as EthPrivateKey).address : null;

  // ---------------------------------------------------------------------------
  // INITIALIZE - Connect to Ethereum network
  // ---------------------------------------------------------------------------
  // Called once when app starts
  Future<void> initialize() async {
    if (_isInitialized) {
      print('Web3Service already initialized');
      return;
    }

    try {
      // Connect to Ganache (local Ethereum blockchain)
      // 10.0.2.2 is special IP for Android emulator to reach host machine
      _rpcUrl = 'http://10.0.2.2:7545';
      _client = Web3Client(_rpcUrl, Client());

      // Load saved wallet if user previously connected
      await _loadStoredCredentials();

      // Load our smart contract
      _loadContract();

      _isInitialized = true;
      print('Web3Service initialized successfully');
      print('  - Wallet connected: $isConnected');
      print('  - Contract ready: $isContractReady');
    } catch (e) {
      print('Web3Service initialization error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD STORED CREDENTIALS - Get saved wallet from device
  // ---------------------------------------------------------------------------
  Future<void> _loadStoredCredentials() async {
    try {
      // Read private key from secure storage
      final privateKey = await _storage.read(key: 'private_key');
      if (privateKey != null && privateKey.isNotEmpty) {
        // Convert private key string to credentials
        _credentials = EthPrivateKey.fromHex(privateKey);
        final address = (_credentials as EthPrivateKey).address;
        print('Wallet loaded from storage: ${address.hex}');
      } else {
        print('No wallet stored');
      }
    } catch (e) {
      print('Error loading stored credentials: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD CONTRACT - Set up connection to our smart contract
  // ---------------------------------------------------------------------------
  void _loadContract() {
    // ABI = Application Binary Interface
    // Tells our app what functions the contract has
    const String abi = '''
    [
      {"inputs":[{"internalType":"string","name":"_courseId","type":"string"},{"internalType":"uint256","name":"_price","type":"uint256"}],"name":"createCourse","outputs":[],"stateMutability":"nonpayable","type":"function"},
      {"inputs":[{"internalType":"string","name":"_courseId","type":"string"}],"name":"purchaseCourse","outputs":[],"stateMutability":"payable","type":"function"},
      {"inputs":[{"internalType":"address","name":"_student","type":"address"}],"name":"getEnrolledCourses","outputs":[{"internalType":"string[]","name":"","type":"string[]"}],"stateMutability":"view","type":"function"}
    ]
    ''';

    // Contract address - where our smart contract lives on blockchain
    // This address is from deploying to Ganache
    const String contractAddressHex =
        '0x6D26f1905b342F47934ca6de17F7d4f3BFFC3026';

    try {
      _contractAddress = EthereumAddress.fromHex(contractAddressHex);
      _contract = DeployedContract(
        ContractAbi.fromJson(abi, 'CourseMarketplace'),
        _contractAddress!,
      );
      print('Contract loaded at: $contractAddressHex');
    } catch (e) {
      print('Error loading contract: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // CONNECT WALLET - User enters their private key
  // ---------------------------------------------------------------------------
  // In real app, would use WalletConnect or MetaMask
  Future<void> connectWallet(String privateKey) async {
    try {
      // Convert private key to usable credentials
      _credentials = EthPrivateKey.fromHex(privateKey);

      // Save to secure storage for next time
      await _storage.write(key: 'private_key', value: privateKey);

      final address = (_credentials as EthPrivateKey).address;
      print('Wallet connected: ${address.hex}');
    } catch (e) {
      print('Error connecting wallet: $e');
      throw Exception('Invalid Private Key');
    }
  }

  // ---------------------------------------------------------------------------
  // DISCONNECT WALLET - Remove wallet connection
  // ---------------------------------------------------------------------------
  Future<void> disconnectWallet() async {
    await _storage.delete(key: 'private_key');
    _credentials = null;
  }

  // ---------------------------------------------------------------------------
  // CREATE COURSE ON BLOCKCHAIN - Instructor registers course
  // ---------------------------------------------------------------------------
  Future<String> createCourseOnChain(String courseId, double priceEth) async {
    // Check everything is ready
    if (_client == null || _credentials == null || _contract == null) {
      throw Exception('Web3 not initialized or wallet not connected');
    }

    // Get the contract function we want to call
    final function = _contract!.function('createCourse');

    // Convert ETH price to Wei (smallest unit)
    // 1 ETH = 1,000,000,000,000,000,000 Wei (10^18)
    final priceInWei = BigInt.from((priceEth * 1e18).toInt());

    try {
      print('Creating course on blockchain: $courseId (${priceEth} ETH)');

      // Send transaction to blockchain
      final transactionHash = await _client!.sendTransaction(
        _credentials!,
        Transaction.callContract(
          contract: _contract!,
          function: function,
          parameters: [courseId, priceInWei],
        ),
        chainId: 1337, // Ganache chain ID
      );

      print('Course created on-chain: $transactionHash');
      return transactionHash;
    } catch (e) {
      print('Create course failed: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PURCHASE COURSE - Student buys course with ETH
  // ---------------------------------------------------------------------------
  // This is the main blockchain function for buying courses!
  Future<String> purchaseCourse(String courseId, double priceEth) async {
    if (_client == null || _credentials == null || _contract == null) {
      throw Exception('Web3 not initialized or wallet not connected');
    }

    // For demo: Create course on-chain if it doesn't exist
    try {
      await createCourseOnChain(courseId, priceEth);
    } catch (e) {
      print('Course may already exist or creation failed: $e');
    }

    // Get the purchaseCourse function from contract
    final function = _contract!.function('purchaseCourse');

    // Convert ETH to Wei
    // Example: 0.05 ETH = 50,000,000,000,000,000 Wei
    final priceInWei = EtherAmount.inWei(
      BigInt.from((priceEth * 1e18).toInt()),
    );

    try {
      // SEND THE TRANSACTION!
      // This transfers ETH from student to smart contract
      // Smart contract then sends to instructor
      final transactionHash = await _client!.sendTransaction(
        _credentials!,
        Transaction.callContract(
          contract: _contract!,
          function: function,
          parameters: [courseId],
          value: priceInWei, // ETH to send with transaction
        ),
        chainId: 1337,
      );

      print('Transaction sent: $transactionHash');
      return transactionHash;
    } catch (e) {
      // Handle case where user already enrolled
      if (e.toString().contains('Already enrolled')) {
        print('Already enrolled on blockchain - returning success');
        return 'already_enrolled';
      }
      print('Transaction failed: $e');
      rethrow;
    }
  }
}
