import 'merit_credit_ledger_entry.dart';
import 'merit_snapshot.dart';

class MeritHistoryItem {
  final int id;
  final DateTime? periodMonth;
  final double totalScore;
  final double extraPoints;
  final String meritLevel;
  final bool isFundEligible;
  final DateTime? lockedAt;

  const MeritHistoryItem({
    required this.id,
    this.periodMonth,
    required this.totalScore,
    required this.extraPoints,
    required this.meritLevel,
    required this.isFundEligible,
    this.lockedAt,
  });

  factory MeritHistoryItem.fromJson(Map<String, dynamic> json) {
    return MeritHistoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      periodMonth: DateTime.tryParse(json['period_month']?.toString() ?? ''),
      totalScore: double.tryParse(json['total_score']?.toString() ?? '') ?? 0,
      extraPoints:
          double.tryParse(json['extra_points']?.toString() ?? '') ?? 0,
      meritLevel: (json['merit_level'] ?? 'none').toString(),
      isFundEligible: (json['is_fund_eligible'] ?? false) == true,
      lockedAt: DateTime.tryParse(json['locked_at']?.toString() ?? ''),
    );
  }
}

class MeritPlayerMeResponse {
  final MeritSnapshot? current;
  final List<MeritHistoryItem> history;

  const MeritPlayerMeResponse({this.current, this.history = const []});

  factory MeritPlayerMeResponse.fromJson(Map<String, dynamic> json) {
    final rawCurrent = json['current'];
    final rawHistory = json['history'];

    return MeritPlayerMeResponse(
      current: rawCurrent is Map
          ? MeritSnapshot.fromJson(Map<String, dynamic>.from(rawCurrent))
          : null,
      history: rawHistory is List
          ? rawHistory
              .whereType<Map>()
              .map(
                (e) => MeritHistoryItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const <MeritHistoryItem>[],
    );
  }
}

class MeritCreditBalanceResponse {
  final double currentBalanceMxn;
  final List<MeritCreditLedgerEntry> entries;

  const MeritCreditBalanceResponse({
    required this.currentBalanceMxn,
    this.entries = const [],
  });

  factory MeritCreditBalanceResponse.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];

    return MeritCreditBalanceResponse(
      currentBalanceMxn:
          double.tryParse(json['current_balance_mxn']?.toString() ?? '') ?? 0,
      entries: rawEntries is List
          ? rawEntries
              .whereType<Map>()
              .map(
                (e) => MeritCreditLedgerEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const <MeritCreditLedgerEntry>[],
    );
  }
}

class MeritValidateSnapshotResult {
  final MeritSnapshot? snapshot;
  final String message;

  const MeritValidateSnapshotResult({this.snapshot, required this.message});
}
