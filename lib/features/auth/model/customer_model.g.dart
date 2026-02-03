// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerModelAdapter extends TypeAdapter<CustomerModel> {
  @override
  final int typeId = 2;

  @override
  CustomerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerModel(
      customerId: fields[0] as String,
      companyName: fields[1] as String,
      email: fields[2] as String,
      phoneNumber: fields[3] as String,
      password: fields[4] as String,
      certificateStandard: fields[5] as String,
      numberOfLocations: fields[6] as String,
      numberOfEmployees: fields[7] as String,
      companyFunction: fields[8] as String,
      legitDocumentUrl: fields[9] as String,
      isProfileApproved: fields[10] as bool,
      fcmToken: fields[11] as String,
      roleId: fields[12] as String,
      createdAt: fields[13] as DateTime,
      address: fields[14] as String,
      lowLevelName: fields[15] as String,
      lowLevelEmail: fields[16] as String,
      lowLevelMobile: fields[17] as String,
      mediumLevelName: fields[18] as String,
      mediumLevelEmail: fields[19] as String,
      mediumLevelMobile: fields[20] as String,
      topLevelName: fields[21] as String,
      topLevelEmail: fields[22] as String,
      topLevelMobile: fields[23] as String,
      consultantId: fields[24] as String?,
      nextVisitDate: fields[25] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerModel obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.customerId)
      ..writeByte(1)
      ..write(obj.companyName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.password)
      ..writeByte(5)
      ..write(obj.certificateStandard)
      ..writeByte(6)
      ..write(obj.numberOfLocations)
      ..writeByte(7)
      ..write(obj.numberOfEmployees)
      ..writeByte(8)
      ..write(obj.companyFunction)
      ..writeByte(9)
      ..write(obj.legitDocumentUrl)
      ..writeByte(10)
      ..write(obj.isProfileApproved)
      ..writeByte(11)
      ..write(obj.fcmToken)
      ..writeByte(12)
      ..write(obj.roleId)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.address)
      ..writeByte(15)
      ..write(obj.lowLevelName)
      ..writeByte(16)
      ..write(obj.lowLevelEmail)
      ..writeByte(17)
      ..write(obj.lowLevelMobile)
      ..writeByte(18)
      ..write(obj.mediumLevelName)
      ..writeByte(19)
      ..write(obj.mediumLevelEmail)
      ..writeByte(20)
      ..write(obj.mediumLevelMobile)
      ..writeByte(21)
      ..write(obj.topLevelName)
      ..writeByte(22)
      ..write(obj.topLevelEmail)
      ..writeByte(23)
      ..write(obj.topLevelMobile)
      ..writeByte(24)
      ..write(obj.consultantId)
      ..writeByte(25)
      ..write(obj.nextVisitDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
