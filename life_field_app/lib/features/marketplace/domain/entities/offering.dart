import 'package:json_annotation/json_annotation.dart';

part 'offering.g.dart';

@JsonSerializable()
class Offering {
  Offering({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
    this.description,
    this.currency = 'EUR',
  });

  factory Offering.fromJson(Map<String, dynamic> json) => _$OfferingFromJson(json);

  final String id;
  final String title;
  final String type;
  final double price;
  final String currency;
  final String? description;

  Map<String, dynamic> toJson() => _$OfferingToJson(this);
}
