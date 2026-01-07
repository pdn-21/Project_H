import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visit_model.dart';

class VisitDataTable extends StatelessWidget {
  final List<VisitModel> visits;

  const VisitDataTable({
    super.key,
    required this.visits,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Colors.grey[100],
          ),
          columns: const [
            DataColumn(
                label:
                    Text('VN', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label:
                    Text('HN', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label:
                    Text('CID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('PATIENT NAME',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('DATE',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('VSTTIME',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('PTTYPE',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('DEPARTMENT',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('OUTDEPARTMENT',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('REVENUE',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('UC MONEY',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('CLAIM CODE',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('CLAIM STATUS',
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: visits.map((visit) {
            return DataRow(
              cells: [
                DataCell(Text(visit.vn)),
                DataCell(Text(visit.hn)),
                DataCell(Text(visit.cid)),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      visit.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(visit.vstdate),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(Text(visit.vsttime ?? '--')),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPttypeColor(visit.pttype),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      visit.pttype ?? '--',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      visit.department ?? '--',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      visit.outdepcode ?? '--',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatMoney(visit.income),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatMoney(visit.ucMoney),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
                DataCell(
                  visit.endpoint != null && visit.endpoint!.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                visit.endpoint!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '--',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
                DataCell(
                  _buildStatusBadge(visit.endpoint),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _formatMoney(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  Color _getPttypeColor(String? pttype) {
    if (pttype == null) return Colors.grey;

    switch (pttype.toUpperCase()) {
      case 'A1':
      case 'A7':
        return Colors.blue;
      case 'UC':
        return Colors.green;
      case 'OFC':
        return Colors.orange;
      case 'LGO':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String? endpoint) {
    if (endpoint != null && endpoint.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: Colors.green,
            ),
            SizedBox(width: 4),
            Text(
              '✓',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              size: 14,
              color: Colors.orange,
            ),
            SizedBox(width: 4),
            Text(
              'ไม่มี',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }
  }
}
