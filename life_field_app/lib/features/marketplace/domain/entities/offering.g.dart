// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offering.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Offering _$OfferingFromJson(Map<String, dynamic> json) => Offering(
  id: json['id'] as String,
  title: json['title'] as String,
  type: json['type'] as String,
  price: (json['price'] as num).toDouble(),
  description: json['description'] as String?,
  currency: json['currency'] as String? ?? 'EUR',
);

Map<String, dynamic> _$OfferingToJson(Offering instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'type': instance.type,
  'price': instance.price,
  'currency': instance.currency,
  'description': instance.description,
};
