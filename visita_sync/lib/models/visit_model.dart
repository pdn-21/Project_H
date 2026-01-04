class VisitModel {
  final String vn;
  final String vstdate;
  final String hn;
  final String name;
  final String cid;
  final String? pttype;
  final String? pttypename;
  final String? department;
  final String? authCode;
  final String? closeSeq;
  final String? closeStaff;
  final double income;
  final double ucMoney;
  final double paidMoney;
  final double arrearage;
  final String? outdepcode;
  final String? vsttime;
  final String? ovstost;
  final String? endpoint;
  final String? closeVisit;
  final String? date;

  VisitModel({
    required this.vn,
    required this.vstdate,
    required this.hn,
    required this.name,
    required this.cid,
    this.pttype,
    this.pttypename,
    this.department,
    this.authCode,
    this.closeSeq,
    this.closeStaff,
    this.income = 0,
    this.ucMoney = 0,
    this.paidMoney = 0,
    this.arrearage = 0,
    this.outdepcode,
    this.vsttime,
    this.ovstost,
    this.endpoint,
    this.closeVisit,
    this.date,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      vn: json['vn']?.toString() ?? '',
      vstdate: json['vstdate']?.toString() ?? '',
      hn: json['hn']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cid: json['cid']?.toString() ?? '',
      pttype: json['pttype']?.toString() ?? '',
      pttypename: json['pttypename']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      authCode: json['auth_code']?.toString() ?? '',
      closeSeq: json['close_seq']?.toString() ?? '',
      closeStaff: json['close_staff']?.toString() ?? '',
      income: double.tryParse(json['income']?.toString() ?? '0') ?? 0,
      ucMoney: double.tryParse(json['uc_money']?.toString() ?? '0') ?? 0,
      paidMoney: double.tryParse(json['paid_money']?.toString() ?? '0') ?? 0,
      arrearage: double.tryParse(json['arrearage']?.toString() ?? '0') ?? 0,
      outdepcode: json['outdepcode']?.toString() ?? '',
      vsttime: json['vsttime']?.toString() ?? '',
      ovstost: json['ovstost']?.toString() ?? '',
      endpoint: json['endpoint']?.toString() ?? '',
      closeVisit: json['close_visit']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vn': vn,
      'vstdate': vstdate,
      'hn': hn,
      'name': name,
      'cid': cid,
      'pttype': pttype,
      'pttypename': pttypename,
      'department': department,
      'auth_code': authCode,
      'close_seq': closeSeq,
      'close_staff': closeStaff,
      'income': income,
      'uc_money': ucMoney,
      'paid_money': paidMoney,
      'arrearage': arrearage,
      'outdepcode': outdepcode,
      'vsttime': vsttime,
      'ovstost': ovstost,
      'endpoint': endpoint,
      'close_visit': closeVisit,
      'date': date,
    };
  }
}
