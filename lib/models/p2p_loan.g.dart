// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'p2p_loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class P2PLoanAdapter extends TypeAdapter<P2PLoan> {
  @override
  final int typeId = 2;

  @override
  P2PLoan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return P2PLoan(
      id: fields[0] as String,
      personName: fields[1] as String,
      amount: fields[2] as double,
      isLent: fields[3] as bool,
      date: fields[4] as DateTime,
      notes: fields[5] as String?,
      repaidAmount: fields[6] as double,
      dueDate: fields[7] as DateTime?,
      phoneNumber: fields[8] as String?,
      interestRate: fields[9] as double?,
      tenureMonths: fields[10] as int?,
      isFlat: fields[11] as bool,
      interestPeriod: fields[12] as String,
      principalRepaid: fields[13] as double,
      paymentLog: (fields[14] as List?)?.cast<String>(),
      monthlyDueDay: fields[15] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, P2PLoan obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isLent)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.repaidAmount)
      ..writeByte(7)
      ..write(obj.dueDate)
      ..writeByte(8)
      ..write(obj.phoneNumber)
      ..writeByte(9)
      ..write(obj.interestRate)
      ..writeByte(10)
      ..write(obj.tenureMonths)
      ..writeByte(11)
      ..write(obj.isFlat)
      ..writeByte(12)
      ..write(obj.interestPeriod)
      ..writeByte(13)
      ..write(obj.principalRepaid)
      ..writeByte(14)
      ..write(obj.paymentLog)
      ..writeByte(15)
      ..write(obj.monthlyDueDay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is P2PLoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
