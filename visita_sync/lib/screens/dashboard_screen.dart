import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/visit_provider.dart';
import '../widgets/status_indicator.dart';
import '../widgets/visit_data_table.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  String? _selectedPttype;
  String? _selectedClaimCode;
  String? _selectedClaimStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VisitProvider>(context, listen: false);
      provider.initialize().then((_) {
        if (provider.isLocalDbConnected) {
          _loadData();
        }
      });
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<VisitProvider>(context, listen: false);
    final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(_toDate);
    await provider.loadVisits(fromStr, toStr);
  }

  Future<void> _syncData() async {
    final provider = Provider.of<VisitProvider>(context, listen: false);

    if (!provider.isSourceDbConnected) {
      _showErrorDialog('ไม่สามารถเชื่อมต่อ Source Database');
      return;
    }

    final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(_toDate);

    await provider.syncData(fromStr, toStr);

    if (provider.errorMessage == null) {
      _showSuccessSnackbar('ซิงค์ข้อมูลสำเร็จ');
    } else {
      _showErrorDialog(provider.errorMessage!);
    }
  }

  Future<void> _checkAuthen() async {
    final provider = Provider.of<VisitProvider>(context, listen: false);

    if (!provider.isNhsoApiConnected) {
      _showErrorDialog('ไม่สามารถเชื่อมต่อ NHSO API');
      return;
    }

    final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(_toDate);

    await provider.checkAuthenStatus(fromStr, toStr);

    if (provider.errorMessage != null) {
      _showSuccessSnackbar(provider.errorMessage!);
    }
  }

  Future<void> _exportExcel() async {
    final provider = Provider.of<VisitProvider>(context, listen: false);

    if (provider.visits.isEmpty) {
      _showErrorDialog('ไม่มีข้อมูลให้ส่งออก');
      return;
    }

    final success = await provider.exportToExcel();

    if (success) {
      _showSuccessSnackbar('ส่งออก Excel สำเร็จ');
    } else {
      _showErrorDialog('ส่งออก Excel ไม่สำเร็จ');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('ข้อผิดพลาด'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildStatusBar(),
          _buildFilterBar(),
          Expanded(child: _buildDataSection()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, size: 32, color: Colors.blue),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Visit Data',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Manage, verify, and sync hospital visit records efficiently.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
          Consumer<VisitProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  StatusIndicator(
                    label: 'LOCAL DATABASE',
                    isConnected: provider.isLocalDbConnected,
                  ),
                  const SizedBox(width: 16),
                  StatusIndicator(
                    label: 'BACKEND SERVICE',
                    isConnected: provider.isNhsoApiConnected,
                    responseTime: '345ms',
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildDateSelector(),
          const SizedBox(width: 16),
          _buildSyncButton(),
          const SizedBox(width: 16),
          _buildCheckAuthenButton(),
          const SizedBox(width: 16),
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 8),
            Text(
              'Range: ${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return Consumer<VisitProvider>(
      builder: (context, provider, child) {
        return ElevatedButton.icon(
          onPressed: provider.isLoading ? null : _syncData,
          icon: provider.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: const Text('Sync Data (HOSxP)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        );
      },
    );
  }

  Widget _buildCheckAuthenButton() {
    return Consumer<VisitProvider>(
      builder: (context, provider, child) {
        return ElevatedButton.icon(
          onPressed: provider.isLoading ? null : _checkAuthen,
          icon: const Icon(Icons.verified_user),
          label: const Text('Check Authen (NHSO)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        );
      },
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: _exportExcel,
      icon: const Icon(Icons.file_download),
      label: const Text('Export Excel'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          _buildFilterDropdown(
            label: 'Pttype',
            icon: Icons.medical_services,
            value: _selectedPttype,
            items: ['All', 'A1', 'A7', 'UC', 'OFC', 'LGO'],
            onChanged: (value) => setState(() => _selectedPttype = value),
          ),
          const SizedBox(width: 16),
          _buildFilterDropdown(
            label: 'Claim Code',
            icon: Icons.qr_code,
            value: _selectedClaimCode,
            items: ['All', 'Has', 'None'],
            onChanged: (value) => setState(() => _selectedClaimCode = value),
          ),
          const SizedBox(width: 16),
          _buildFilterDropdown(
            label: 'Claim Status',
            icon: Icons.check_circle_outline,
            value: _selectedClaimStatus,
            items: ['All', 'Approved', 'Pending', 'Rejected'],
            onChanged: (value) => setState(() => _selectedClaimStatus = value),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDataHeader(),
          const Divider(height: 1),
          Expanded(
            child: Consumer<VisitProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.visits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีข้อมูล',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'กรุณาเลือกช่วงวันที่และกดปุ่ม Sync Data',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter data
                var filteredVisits = provider.visits;

                if (_selectedPttype != null && _selectedPttype != 'All') {
                  filteredVisits = filteredVisits
                      .where((v) => v.pttype == _selectedPttype)
                      .toList();
                }

                if (_selectedClaimCode != null && _selectedClaimCode != 'All') {
                  if (_selectedClaimCode == 'Has') {
                    filteredVisits = filteredVisits
                        .where(
                            (v) => v.endpoint != null && v.endpoint!.isNotEmpty)
                        .toList();
                  } else {
                    filteredVisits = filteredVisits
                        .where((v) => v.endpoint == null || v.endpoint!.isEmpty)
                        .toList();
                  }
                }

                return VisitDataTable(visits: filteredVisits);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataHeader() {
    return Consumer<VisitProvider>(
      builder: (context, provider, child) {
        final totalVisits = provider.visits.length;
        final withClaimCode = provider.visits
            .where((v) => v.endpoint != null && v.endpoint!.isNotEmpty)
            .length;
        final noClaimCode = totalVisits - withClaimCode;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildStatCard(
                'TOTAL VISITS',
                totalVisits.toString(),
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                'WITH CLAIM CODE',
                withClaimCode.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                'NO CLAIM CODE',
                noClaimCode.toString(),
                Icons.warning,
                Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
