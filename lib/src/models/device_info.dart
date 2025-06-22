/// Device information captured for context
class DeviceInfo {
  const DeviceInfo({
    this.platform,
    this.platformVersion,
    this.deviceModel,
    this.deviceId,
    this.appVersion,
    this.buildNumber,
  });

  final String? platform;
  final String? platformVersion;
  final String? deviceModel;
  final String? deviceId;
  final String? appVersion;
  final String? buildNumber;

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'platformVersion': platformVersion,
        'deviceModel': deviceModel,
        'deviceId': deviceId,
        'appVersion': appVersion,
        'buildNumber': buildNumber,
      };

  DeviceInfo copyWith({
    String? platform,
    String? platformVersion,
    String? deviceModel,
    String? deviceId,
    String? appVersion,
    String? buildNumber,
  }) {
    return DeviceInfo(
      platform: platform ?? this.platform,
      platformVersion: platformVersion ?? this.platformVersion,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceId: deviceId ?? this.deviceId,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfo &&
          runtimeType == other.runtimeType &&
          platform == other.platform &&
          platformVersion == other.platformVersion &&
          deviceModel == other.deviceModel &&
          deviceId == other.deviceId &&
          appVersion == other.appVersion &&
          buildNumber == other.buildNumber;

  @override
  int get hashCode =>
      platform.hashCode ^
      platformVersion.hashCode ^
      deviceModel.hashCode ^
      deviceId.hashCode ^
      appVersion.hashCode ^
      buildNumber.hashCode;
}
