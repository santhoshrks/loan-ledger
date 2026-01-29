// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 0;

  @override
  Loan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String,
      name: fields[1] as String,
      emiAmount: fields[2] as double,
      dueDay: fields[3] as int,
      startDate: fields[4] as DateTime,
      notes: fields[5] as String?,
      loanAmount: fields[6] as double?,
      interestRate: fields[7] as double?,
      tenureMonths: fields[8] as int?,
      isPaid: fields[9] as bool? ?? false,
      currencyCode: fields[10] as String? ?? 'INR', // Default to INR for backward compatibility
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emiAmount)
      ..writeByte(3)
      ..write(obj.dueDay)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.loanAmount)
      ..writeByte(7)
      ..write(obj.interestRate)
      ..writeByte(8)
      ..write(obj.tenureMonths)
      ..writeByte(9)
      ..write(obj.isPaid)
      ..writeByte(10)
      ..write(obj.currencyCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
