class DatabaseSettings {
  // * Local Database
  final String localHost;
  final int localPort;
  final String localDatabase;
  final String localUsername;
  final String localPassword;

  // * Source Database
  final String sourceHost;
  final int sourcePort;
  final String sourceDatabase;
  final String sourceUsername;
  final String sourcePassword;

  // * NHSO API
  final String nhsoApiUrl;
  final String nhsoTokenHeader;
  final String nhsoAccessToken;

  DatabaseSettings({
    this.localHost = 'localhost',
    this.localPort = 3306,
    this.localDatabase = 'visita_sync',
    this.localUsername = 'sa',
    this.localPassword = '',
    this.sourceHost = '192.168.1.100',
    this.sourcePort = 3306,
    this.sourceDatabase = 'hosxp',
    this.sourceUsername = 'sa',
    this.sourcePassword = '',
    this.nhsoApiUrl =
        'https://authenucws.nhso.go.th/authencodestatus/api/check-authen-status',
    this.nhsoTokenHeader = 'Authorization',
    this.nhsoAccessToken = '',
  });

  factory DatabaseSettings.fromJson(Map<String, dynamic> json) {
    return DatabaseSettings(
      localHost: json['localHost'] ?? 'localhost',
      localPort: json['localPort'] ?? 3306,
      localDatabase: json['localDatabase'] ?? 'visita_sync',
      localUsername: json['localUsername'] ?? 'sa',
      localPassword: json['localPassword'] ?? '',
      sourceHost: json['sourceHost'] ?? '192.168.1.100',
      sourcePort: json['sourcePort'] ?? 3306,
      sourceDatabase: json['sourceDatabase'] ?? 'hosxp',
      sourceUsername: json['sourceUsername'] ?? 'sa',
      sourcePassword: json['sourcePassword'] ?? '',
      nhsoApiUrl: json['nhsoApiUrl'] ??
          'https://authenucws.nhso.go.th/authencodestatus/api/check-authen-status',
      nhsoTokenHeader: json['nhsoTokenHeader'] ?? 'Authorization',
      nhsoAccessToken: json['nhsoAccessToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localHost': localHost,
      'localPort': localPort,
      'localDatabase': localDatabase,
      'localUsername': localUsername,
      'localPassword': localPassword,
      'sourceHost': sourceHost,
      'sourcePort': sourcePort,
      'sourceDatabase': sourceDatabase,
      'sourceUsername': sourceUsername,
      'sourcePassword': sourcePassword,
      'nhsoApiUrl': nhsoApiUrl,
      'nhsoTokenHeader': nhsoTokenHeader,
      'nhsoAccessToken': nhsoAccessToken,
    };
  }
}
