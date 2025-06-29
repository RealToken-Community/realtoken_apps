class ContractsConstants {
  // === ADRESSES DE CONTRATS RMM ===
  static const String usdcDepositContract =
      '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1';
  static const String usdcBorrowContract =
      '0x69c731ae5f5356a779f44c355abb685d84e5e9e6';
  static const String xdaiDepositContract =
      '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b';
  static const String xdaiBorrowContract =
      '0x9908801df7902675c3fedd6fea0294d18d5d5d34';

  // === CONTRATS GNOSIS ===
  static const String gnosisUsdcContract =
      '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83';
  static const String gnosisRegContract =
      '0x0aa1e96d2a46ec6beb2923de1e61addf5f5f1dce';
  static const String gnosisVaultRegContract =
      '0xe1877d33471e37fe0f62d20e60c469eff83fb4a0';

  // === RPC ENDPOINTS ===
  static const String gnosisRpcUrl = 'https://rpc.gnosischain.com';

  // === SELECTEURS DE FONCTION ===
  static const String balanceOfSelector = '0x70a08231';
  static const String vaultBalanceSelector = '0xf262a083';

  // === DÉCIMALES ===
  static const int usdcDecimals = 6;
  static const int xdaiDecimals = 18;
  static const int regDecimals = 18;

  // === DIVISEURS POUR CONVERSION ===
  static final BigInt usdcDivisor = BigInt.from(1e6);
  static final BigInt xdaiDivisor = BigInt.from(1e18);
  static final BigInt regDivisor = BigInt.from(1e18);

  // === ADRESSE DE DONATION ===
  static const String donationWalletAddress =
      '0xdc30b07aebaef3f15544a3801c6cb0f35f0118fc';

  // === DURÉES DE CACHE SPÉCIFIQUES ===
  static const Duration rmmBalancesCacheDuration = Duration(minutes: 15);
  static const Duration rentDataCacheDuration = Duration(hours: 1);
  static const Duration detailedRentCacheDuration = Duration(hours: 2);
  static const Duration propertiesForSaleCacheDuration = Duration(hours: 6);
  static const Duration tokenVolumesCacheDuration = Duration(hours: 4);
  static const Duration transactionsCacheDuration = Duration(hours: 3);
  static const Duration currenciesCacheDuration = Duration(hours: 1);

  // === LIMITES ET SEUILS ===
  static const Duration version429Delay = Duration(minutes: 5);
  static const Duration oneHourInMillis = Duration(hours: 1);

  // === MÉTHODES UTILITAIRES ===

  /// Construit la data pour un appel eth_call balanceOf
  static String buildBalanceOfData(String address) {
    final String paddedAddress =
        address.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
    return '0x$balanceOfSelector$paddedAddress';
  }

  /// Construit la data pour un appel vault balance
  static String buildVaultBalanceData(String address) {
    final String paddedAddress =
        address.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
    return '0x$vaultBalanceSelector$paddedAddress';
  }

  /// Convertit une balance USDC en double
  static double convertUsdcBalance(BigInt balance) {
    return balance / usdcDivisor;
  }

  /// Convertit une balance XDAI/REG en double
  static double convertXdaiBalance(BigInt balance) {
    return balance / xdaiDivisor;
  }

  /// Convertit une balance REG en double
  static double convertRegBalance(BigInt balance) {
    return balance / regDivisor;
  }

  /// Retourne tous les contrats RMM pour les requêtes en lot
  static List<String> getAllRmmContracts() {
    return [
      usdcDepositContract,
      usdcBorrowContract,
      xdaiDepositContract,
      xdaiBorrowContract,
      gnosisUsdcContract,
      gnosisRegContract,
    ];
  }

  /// Map des contrats avec leurs infos (nom, décimales, diviseur)
  static Map<String, Map<String, dynamic>> getContractInfo() {
    return {
      usdcDepositContract: {
        'name': 'USDC Deposit',
        'decimals': usdcDecimals,
        'divisor': usdcDivisor,
        'converter': convertUsdcBalance,
      },
      usdcBorrowContract: {
        'name': 'USDC Borrow',
        'decimals': usdcDecimals,
        'divisor': usdcDivisor,
        'converter': convertUsdcBalance,
      },
      xdaiDepositContract: {
        'name': 'XDAI Deposit',
        'decimals': xdaiDecimals,
        'divisor': xdaiDivisor,
        'converter': convertXdaiBalance,
      },
      xdaiBorrowContract: {
        'name': 'XDAI Borrow',
        'decimals': xdaiDecimals,
        'divisor': xdaiDivisor,
        'converter': convertXdaiBalance,
      },
      gnosisUsdcContract: {
        'name': 'Gnosis USDC',
        'decimals': usdcDecimals,
        'divisor': usdcDivisor,
        'converter': convertUsdcBalance,
      },
      gnosisRegContract: {
        'name': 'Gnosis REG',
        'decimals': regDecimals,
        'divisor': regDivisor,
        'converter': convertRegBalance,
      },
    };
  }
}
