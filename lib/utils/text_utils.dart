import 'package:shared_preferences/shared_preferences.dart';

class TextUtils {
  static Future<double> getTextSizeOffset() async {
    final prefs = await SharedPreferences.getInstance();
    String selectedTextSize = prefs.getString('selectedTextSize') ?? 'normal';
    return selectedTextSize == 'petit'
        ? -2.0
        : selectedTextSize == 'grand'
            ? 2.0
            : 0.0;
  }

  static String truncateWallet(String wallet,
      {int prefixLength = 6, int suffixLength = 4}) {
    if (wallet.length <= prefixLength + suffixLength) {
      return wallet;
    }
    return '${wallet.substring(0, prefixLength)}...${wallet.substring(wallet.length - suffixLength)}';
  }
}
