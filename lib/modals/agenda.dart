import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:flutter/cupertino.dart';

class AgendaCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> portfolio;

  const AgendaCalendar({super.key, required this.portfolio});

  @override
  AgendaCalendarState createState() => AgendaCalendarState();
}

class AgendaCalendarState extends State<AgendaCalendar> {
  late Map<DateTime, List<Map<String, dynamic>>> _events;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _isCalendarCollapsed = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay =
        DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    final dataManager = Provider.of<DataManager>(context, listen: false);
    _events = _extractTransactions(widget.portfolio);
    _addRentEvents(_events, dataManager.rentData);

    // Ajout d'un listener pour le défilement
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // On réduit le calendrier si on scrolle vers le bas
    if (_scrollController.offset > 20 && !_isCalendarCollapsed) {
      setState(() {
        _isCalendarCollapsed = true;
      });
    } else if (_scrollController.offset <= 20 && _isCalendarCollapsed) {
      setState(() {
        _isCalendarCollapsed = false;
      });
    }
  }

  // Fonction pour basculer manuellement l'état du calendrier
  void _toggleCalendarSize() {
    setState(() {
      _isCalendarCollapsed = !_isCalendarCollapsed;
    });
  }

  Map<DateTime, List<Map<String, dynamic>>> _extractTransactions(
      List<Map<String, dynamic>> portfolio) {
    Map<DateTime, List<Map<String, dynamic>>> events = {};
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    for (var token in portfolio) {
      if (token.containsKey('transactions') && token['transactions'] is List) {
        for (var transaction in token['transactions']) {
          if (transaction['dateTime'] != null) {
            DateTime date = transaction['dateTime'] is String
                ? DateTime.parse(transaction['dateTime'])
                : transaction['dateTime'];
            DateTime normalizedDate = DateTime(date.year, date.month, date.day);
            events.putIfAbsent(normalizedDate, () => []);

            events[normalizedDate]!.add({
              'type': 'transaction',
              'amount': transaction['amount'],
              'price':
                  '${currencyUtils.convert(transaction['price'] ?? token['tokenPrice']).toStringAsFixed(2)} ${currencyUtils.currencySymbol}',
              'date': date.toIso8601String(),
              'fullName': token['fullName'],
              'transactionType': transaction['transactionType'] ??
                  S.of(context).unknownTransaction,
            });
          }
        }
      }
    }
    return events;
  }

  void _addRentEvents(Map<DateTime, List<Map<String, dynamic>>> events,
      List<Map<String, dynamic>> rentData) {
    for (var rent in rentData) {
      if (rent['date'] != null) {
        DateTime date = rent['date'] is String
            ? DateTime.parse(rent['date'])
            : rent['date'];
        DateTime normalizedDate = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(normalizedDate, () => []);
        events[normalizedDate]!.add({
          'type': 'rent',
          'amount': rent['rent'],
          'date': date.toIso8601String(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Calendrier avec animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isCalendarCollapsed ? 80 : null,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemGrey6.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                  vertical: _isCalendarCollapsed ? 8 : 12, horizontal: 8),
              child: _isCalendarCollapsed
                  ? _buildCollapsedCalendar()
                  : _buildFullCalendar(isDarkMode, context),
            ),

            const SizedBox(height: 16),

            // Titre de section avec bouton pour contrôler le calendrier
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).portfolio,
                    style: TextStyle(
                      fontSize: 18 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _toggleCalendarSize,
                    child: Icon(
                      _isCalendarCollapsed
                          ? CupertinoIcons.calendar_badge_plus
                          : CupertinoIcons.calendar_badge_minus,
                      color: CupertinoColors.systemBlue.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: (_events.containsKey(_selectedDay) &&
                      _events[_selectedDay]!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: _events[_selectedDay]!.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          indent: 70,
                          color:
                              CupertinoColors.systemGrey5.resolveFrom(context),
                        ),
                        itemBuilder: (context, index) {
                          final event = _events[_selectedDay]![index];
                          final type = event['type'];
                          final fullName = event.containsKey('fullName')
                              ? event['fullName']
                              : "N/A";
                          final date = event['date'];
                          final price = event['price'];
                          final amount = event['amount'] ?? 0.0;
                          final transactionType =
                              event.containsKey('transactionType')
                                  ? event['transactionType']
                                  : S.of(context).unknownTransaction;

                          // Obtenir la version localisée du type de transaction pour l'affichage
                          final localizedTransactionType =
                              _getLocalizedTransactionType(
                                  transactionType, context);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? CupertinoColors.systemGrey6.darkColor
                                  : CupertinoColors.systemGrey6.color,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            child: type == 'transaction'
                                ? Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _getIconBackground(
                                              transactionType, context),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _getTransactionIcon(
                                                transactionType),
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fullName,
                                              style: TextStyle(
                                                fontSize: 16 +
                                                    appState
                                                        .getTextSizeOffset(),
                                                fontWeight: FontWeight.w600,
                                                color: CupertinoColors.label
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "$localizedTransactionType • ${S.of(context).quantity}: $amount",
                                              style: TextStyle(
                                                fontSize: 14 +
                                                    appState
                                                        .getTextSizeOffset(),
                                                color: CupertinoColors
                                                    .secondaryLabel
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                            Text(
                                              price,
                                              style: TextStyle(
                                                fontSize: 14 +
                                                    appState
                                                        .getTextSizeOffset(),
                                                fontWeight: FontWeight.w500,
                                                color: CupertinoColors
                                                    .systemBlue
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemGreen
                                              .resolveFrom(context),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            CupertinoIcons.money_dollar,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              S.of(context).wallet,
                                              style: TextStyle(
                                                fontSize: 16 +
                                                    appState
                                                        .getTextSizeOffset(),
                                                color: CupertinoColors
                                                    .secondaryLabel
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${currencyUtils.convert(amount).toStringAsFixed(2)} ${currencyUtils.currencySymbol}",
                                              style: TextStyle(
                                                fontSize: 15 +
                                                    appState
                                                        .getTextSizeOffset(),
                                                fontWeight: FontWeight.w500,
                                                color: CupertinoColors
                                                    .systemGreen
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? CupertinoColors.systemGrey6.darkColor
                              : CupertinoColors.systemGrey6.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.calendar_badge_minus,
                              size: 50,
                              color: CupertinoColors.systemGrey
                                  .resolveFrom(context),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              S.of(context).wallet,
                              style: TextStyle(
                                fontSize: 16 + appState.getTextSizeOffset(),
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Version compacte du calendrier
  Widget _buildCollapsedCalendar() {
    return GestureDetector(
      onTap: _toggleCalendarSize,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.calendar,
            color: CupertinoColors.systemBlue.resolveFrom(context),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                  style: TextStyle(
                    fontSize: 16 +
                        Provider.of<AppState>(context, listen: false)
                            .getTextSizeOffset(),
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getFormattedDay(_selectedDay),
                  style: TextStyle(
                    fontSize: 14 +
                        Provider.of<AppState>(context, listen: false)
                            .getTextSizeOffset(),
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 30,
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDay =
                        _selectedDay.subtract(const Duration(days: 1));
                    _focusedDay = _selectedDay;
                  });
                },
              ),
              const SizedBox(width: 4),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 30,
                child: Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDay = _selectedDay.add(const Duration(days: 1));
                    _focusedDay = _selectedDay;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Version complète du calendrier
  Widget _buildFullCalendar(bool isDarkMode, BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        DateTime normalizedDay = DateTime(day.year, day.month, day.day);
        return _events[normalizedDay] ?? [];
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay =
              DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
          _focusedDay = focusedDay;
        });
      },
      rowHeight: 46,
      daysOfWeekHeight: 32,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        leftChevronIcon: Icon(CupertinoIcons.chevron_left,
            size: 16, color: CupertinoColors.systemBlue.resolveFrom(context)),
        rightChevronIcon: Icon(CupertinoIcons.chevron_right,
            size: 16, color: CupertinoColors.systemBlue.resolveFrom(context)),
        titleTextStyle: TextStyle(
          fontSize: 18 +
              Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label.resolveFrom(context),
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        markersMaxCount: 4,
        markerSize: 6,
        markerDecoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        markersAlignment: Alignment.bottomCenter,
        markersAnchor: 0.7,
        todayDecoration: BoxDecoration(
          color: CupertinoColors.systemBlue
              .resolveFrom(context)
              .withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        selectedDecoration: BoxDecoration(
          color: CupertinoColors.systemBlue.resolveFrom(context),
          shape: BoxShape.circle,
        ),
        outsideDaysVisible: false,
        cellMargin: const EdgeInsets.all(5),
        weekendTextStyle: TextStyle(
          color: CupertinoColors.systemGrey.resolveFrom(context),
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontSize: 14 +
              Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontWeight: FontWeight.w500,
        ),
        weekendStyle: TextStyle(
          fontSize: 14 +
              Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
          color: CupertinoColors.systemGrey.resolveFrom(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;
          List<Widget> markers = [];

          bool hasRent =
              events.any((e) => (e as Map<String, dynamic>)['type'] == 'rent');
          bool hasPurchase = events.any((e) =>
              (e as Map<String, dynamic>)['type'] == 'transaction' &&
              e['transactionType'] == DataManager.transactionTypePurchase);
          bool hasYAM = events.any((e) =>
              (e as Map<String, dynamic>)['type'] == 'transaction' &&
              e['transactionType'] == DataManager.transactionTypeYam);
          bool hasTransfer = events.any((e) =>
              (e as Map<String, dynamic>)['type'] == 'transaction' &&
              e['transactionType'] == DataManager.transactionTypeTransfer);

          if (hasRent) {
            markers.add(Container(
                margin: const EdgeInsets.only(left: 1, right: 1),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.resolveFrom(context),
                    shape: BoxShape.circle)));
          }
          if (hasPurchase) {
            markers.add(Container(
                margin: const EdgeInsets.only(left: 1, right: 1),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.resolveFrom(context),
                    shape: BoxShape.circle)));
          }
          if (hasYAM) {
            markers.add(Container(
                margin: const EdgeInsets.only(left: 1, right: 1),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange.resolveFrom(context),
                    shape: BoxShape.circle)));
          }
          if (hasTransfer) {
            markers.add(Container(
                margin: const EdgeInsets.only(left: 1, right: 1),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    shape: BoxShape.circle)));
          }

          return markers.isNotEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: markers)
              : null;
        },
      ),
    );
  }

  // Fonction pour obtenir le jour de la semaine formaté
  String _getFormattedDay(DateTime date) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    // Le weekday de DateTime va de 1 (lundi) à 7 (dimanche)
    final dayIndex = date.weekday - 1;
    return days[dayIndex];
  }

  IconData _getTransactionIcon(String transactionType) {
    if (transactionType == DataManager.transactionTypePurchase) {
      return CupertinoIcons.cart_fill;
    } else if (transactionType == DataManager.transactionTypeTransfer) {
      return CupertinoIcons.arrow_right_arrow_left_square_fill;
    } else if (transactionType == DataManager.transactionTypeYam) {
      return CupertinoIcons.money_dollar_circle_fill;
    } else {
      return CupertinoIcons.creditcard_fill;
    }
  }

  Color _getIconBackground(String transactionType, BuildContext context) {
    if (transactionType == DataManager.transactionTypePurchase) {
      return CupertinoColors.systemBlue.resolveFrom(context);
    } else if (transactionType == DataManager.transactionTypeTransfer) {
      return CupertinoColors.systemGrey.resolveFrom(context);
    } else if (transactionType == DataManager.transactionTypeYam) {
      return CupertinoColors.systemOrange.resolveFrom(context);
    } else {
      return CupertinoColors.systemTeal.resolveFrom(context);
    }
  }

  // Méthode pour traduire les constantes en textes localisés
  String _getLocalizedTransactionType(
      String transactionType, BuildContext context) {
    if (transactionType == DataManager.transactionTypePurchase) {
      return S.of(context).purchase;
    } else if (transactionType == DataManager.transactionTypeTransfer) {
      return S.of(context).internal_transfer;
    } else if (transactionType == DataManager.transactionTypeYam) {
      return S.of(context).yam;
    } else {
      return S.of(context).unknownTransaction;
    }
  }
}
