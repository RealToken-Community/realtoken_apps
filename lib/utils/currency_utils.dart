import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realtoken_asset_tracker/services/api_service.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  double _conversionRate = 1.0; // Taux de conversion par défaut
  String _selectedCurrency = 'usd'; // Devise par défaut
  String _currencySymbol = '\$'; // Symbole par défaut

  double get conversionRate => _conversionRate;
  String get selectedCurrency => _selectedCurrency;
  String get currencySymbol => _currencySymbol;

  CurrencyProvider() {
    loadSelectedCurrency(); // Charge la devise au démarrage
  }

  Future<void> loadSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString('selectedCurrency') ?? 'usd';

    final currencies = await ApiService.fetchCurrencies();
    await updateConversionRate(_selectedCurrency, currencies);

    notifyListeners(); // ✅ Force l'UI à se mettre à jour
  }

  Future<void> updateConversionRate(
      String currency, Map<String, dynamic> currencies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'selectedCurrency', currency); // ✅ Sauvegarde la nouvelle devise

    _selectedCurrency = currency;

    if (_selectedCurrency == "usd") {
      _conversionRate = 1.0;
    } else if (currencies.containsKey(_selectedCurrency)) {
      _conversionRate = currencies[_selectedCurrency] is double
          ? currencies[_selectedCurrency]
          : 1.0;
    } else {
      _conversionRate = 1.0;
    }

    _currencySymbol = Parameters.currencySymbols[_selectedCurrency] ??
        _selectedCurrency.toUpperCase();

    notifyListeners(); // 🔥 Notifie l'UI qu'un changement a eu lieu
  }

  double convert(double valueInUsd) {
    return valueInUsd * _conversionRate;
  }

  String formatCurrency(double value, String symbol) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: symbol, // Utilisation du symbole sélectionné
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  // Méthode pour formater ou masquer les montants en série de ****
  String getFormattedAmount(double value, String symbol, bool showAmount) {
    if (showAmount) {
      return formatCurrency(
          value, symbol); // Affiche le montant formaté si visible
    } else {
      String formattedValue =
          formatCurrency(value, symbol); // Format le montant normalement
      return '*' *
          formattedValue
              .length; // Retourne une série d'astérisques de la même longueur
    }
  }

  // Méthode pour formater les grands nombres
  String formatCompactCurrency(double value, String symbol) {
    // Si la valeur a plus de 4 chiffres, on utilise le format compact
    if (value >= 10000) {
      // Divise par 1000 et ajoute le suffixe "k"
      double compactValue = value / 1000;
      // Formatage sans décimales
      String formattedValue = compactValue.toInt().toString();

      // Position du symbole en fonction de la devise
      // Devises qui s'affichent après le montant
      List<String> postfixSymbols = ['€', '£', '¥', '₽', '₿', '₹'];
      if (postfixSymbols.contains(symbol)) {
        return '$formattedValue k$symbol';
      }
      // Devises qui s'affichent avant le montant
      else {
        return '$symbol$formattedValue k';
      }
    }
    // Pour les valeurs inférieures à 10000, on utilise le formatage normal sans décimales
    else {
      return formatCurrency(value, symbol).replaceAll(RegExp(r'\,\d+'), '');
    }
  }
}
