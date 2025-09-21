import 'package:cloud_firestore/cloud_firestore.dart';

class MarketPrice {
  final String id;
  final String cropName;
  final String marketName;
  final String location;
  final double pricePerKg;
  final String currency;
  final DateTime date;
  final PriceUnit unit;
  final String? grade;
  final MarketSource source;

  MarketPrice({
    required this.id,
    required this.cropName,
    required this.marketName,
    required this.location,
    required this.pricePerKg,
    required this.currency,
    required this.date,
    required this.unit,
    this.grade,
    required this.source,
  });

  factory MarketPrice.fromMap(Map<String, dynamic> map) {
    return MarketPrice(
      id: map['id'] ?? '',
      cropName: map['cropName'] ?? '',
      marketName: map['marketName'] ?? '',
      location: map['location'] ?? '',
      pricePerKg: map['pricePerKg']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unit: PriceUnit.values.firstWhere(
        (e) => e.toString() == 'PriceUnit.${map['unit']}',
        orElse: () => PriceUnit.kg,
      ),
      grade: map['grade'],
      source: MarketSource.values.firstWhere(
        (e) => e.toString() == 'MarketSource.${map['source']}',
        orElse: () => MarketSource.government,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropName': cropName,
      'marketName': marketName,
      'location': location,
      'pricePerKg': pricePerKg,
      'currency': currency,
      'date': Timestamp.fromDate(date),
      'unit': unit.toString().split('.').last,
      'grade': grade,
      'source': source.toString().split('.').last,
    };
  }
}

class PriceTrend {
  final String cropName;
  final List<PricePoint> prices;
  final TrendDirection direction;
  final double changePercentage;
  final Duration period;

  PriceTrend({
    required this.cropName,
    required this.prices,
    required this.direction,
    required this.changePercentage,
    required this.period,
  });

  factory PriceTrend.fromMap(Map<String, dynamic> map) {
    return PriceTrend(
      cropName: map['cropName'] ?? '',
      prices:
          (map['prices'] as List?)
              ?.map((item) => PricePoint.fromMap(item))
              .toList() ??
          [],
      direction: TrendDirection.values.firstWhere(
        (e) => e.toString() == 'TrendDirection.${map['direction']}',
        orElse: () => TrendDirection.stable,
      ),
      changePercentage: map['changePercentage']?.toDouble() ?? 0.0,
      period: Duration(days: map['periodDays'] ?? 7),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropName': cropName,
      'prices': prices.map((p) => p.toMap()).toList(),
      'direction': direction.toString().split('.').last,
      'changePercentage': changePercentage,
      'periodDays': period.inDays,
    };
  }
}

class PricePoint {
  final DateTime date;
  final double price;

  PricePoint({required this.date, required this.price});

  factory PricePoint.fromMap(Map<String, dynamic> map) {
    return PricePoint(
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      price: map['price']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': Timestamp.fromDate(date), 'price': price};
  }
}

class PriceAlert {
  final String id;
  final String userId;
  final String cropName;
  final double targetPrice;
  final AlertCondition condition;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? triggeredAt;

  PriceAlert({
    required this.id,
    required this.userId,
    required this.cropName,
    required this.targetPrice,
    required this.condition,
    this.isActive = true,
    required this.createdAt,
    this.triggeredAt,
  });

  factory PriceAlert.fromMap(Map<String, dynamic> map) {
    return PriceAlert(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      cropName: map['cropName'] ?? '',
      targetPrice: map['targetPrice']?.toDouble() ?? 0.0,
      condition: AlertCondition.values.firstWhere(
        (e) => e.toString() == 'AlertCondition.${map['condition']}',
        orElse: () => AlertCondition.above,
      ),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      triggeredAt: (map['triggeredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'cropName': cropName,
      'targetPrice': targetPrice,
      'condition': condition.toString().split('.').last,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'triggeredAt': triggeredAt != null
          ? Timestamp.fromDate(triggeredAt!)
          : null,
    };
  }
}

enum PriceUnit { kg, quintal, ton, pound }

enum MarketSource { government, private, cooperative, online }

enum TrendDirection { up, down, stable }

enum AlertCondition { above, below, equal }
