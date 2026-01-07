import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/database_settings.dart';
import '../providers/visit_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Local Database Controllers
  final _localHostController = TextEditingController();
  final _localPortController = TextEditingController();
  final _localDatabaseController = TextEditingController();
  final _localUsernameController = TextEditingController();
  final _localPasswordController = TextEditingController();

  // Source Database Controllers
  final _sourceHostController = TextEditingController();
  final _sourcePortController = TextEditingController();
  final _sourceDatabaseController = TextEditingController();
  final _sourceUsernameController = TextEditingController();
  final _sourcePasswordController = TextEditingController();

  // NHSO API Controllers
  final _nhsoApiUrlController = TextEditingController();
  final _nhsoTokenHeaderController = TextEditingController();
  final _nhsoAccessTokenController = TextEditingController();

  bool _isLocalPasswordVisible = false;
  bool _isSourcePasswordVisible = false;
  bool _isTokenVisible = false;
  bool _isTesting = false;

  Map<String, bool> _testResults = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final provider = Provider.of<VisitProvider>(context, listen: false);
    final settings = provider.currentSettings;

    if (provider.config.hasSettings) {
      _localHostController.text = settings.localHost;
      _localPortController.text = settings.localPort.toString();
      _localDatabaseController.text = settings.localDatabase;
      _localUsernameController.text = settings.localUsername;
      _localPasswordController.text = settings.localPassword;

      _sourceHostController.text = settings.sourceHost;
      _sourcePortController.text = settings.sourcePort.toString();
      _sourceDatabaseController.text = settings.sourceDatabase;
      _sourceUsernameController.text = settings.sourceUsername;
      _sourcePasswordController.text = settings.sourcePassword;

      _nhsoApiUrlController.text = settings.nhsoApiUrl;
      _nhsoTokenHeaderController.text = settings.nhsoTokenHeader;
      _nhsoAccessTokenController.text = settings.nhsoAccessToken;
    }
  }

  Future<void> _testConnections() async {
    setState(() => _isTesting = true);

    final settings = _buildSettings();
    final provider = Provider.of<VisitProvider>(context, listen: false);

    final results = await provider.testConnections(settings);

    setState(() {
      _testResults = results;
      _isTesting = false;
    });

    _showTestResults(results);
  }

  void _showTestResults(Map<String, bool> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ผลการทดสอบการเชื่อมต่อ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('Local Database', results['local'] ?? false),
            _buildResultRow('Source Database', results['source'] ?? false),
            _buildResultRow('NHSO API', results['nhso'] ?? false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.cancel,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  DatabaseSettings _buildSettings() {
    return DatabaseSettings(
      localHost: _localHostController.text,
      localPort: int.tryParse(_localPortController.text) ?? 5432,
      localDatabase: _localDatabaseController.text,
      localUsername: _localUsernameController.text,
      localPassword: _localPasswordController.text,
      sourceHost: _sourceHostController.text,
      sourcePort: int.tryParse(_sourcePortController.text) ?? 3306,
      sourceDatabase: _sourceDatabaseController.text,
      sourceUsername: _sourceUsernameController.text,
      sourcePassword: _sourcePasswordController.text,
      nhsoApiUrl: _nhsoApiUrlController.text,
      nhsoTokenHeader: _nhsoTokenHeaderController.text,
      nhsoAccessToken: _nhsoAccessTokenController.text,
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settings = _buildSettings();
      final provider = Provider.of<VisitProvider>(context, listen: false);

      final saved = await provider.updateSettings(settings);

      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ บันทึกการตั้งค่าสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ บันทึกการตั้งค่าไม่สำเร็จ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าระบบ'),
        actions: [
          if (_isTesting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'บันทึกการตั้งค่า',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocalDatabaseSection(),
              const SizedBox(height: 32),
              _buildSourceDatabaseSection(),
              const SizedBox(height: 32),
              _buildNhsoApiSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalDatabaseSection() {
    return _buildSection(
      title: 'Local Database',
      subtitle: 'TARGET DESTINATION',
      icon: Icons.storage,
      color: Colors.green,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _localHostController,
                decoration: const InputDecoration(
                  labelText: 'Hostname',
                  prefixIcon: Icon(Icons.dns),
                ),
                validator: (v) => v!.isEmpty ? 'กรุณากรอก Hostname' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _localPortController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'กรุณากรอก Port' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _localDatabaseController,
          decoration: const InputDecoration(
            labelText: 'Database Name',
            prefixIcon: Icon(Icons.dataset),
          ),
          validator: (v) => v!.isEmpty ? 'กรุณากรอก Database Name' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _localUsernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'กรุณากรอก Username' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _localPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isLocalPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() =>
                          _isLocalPasswordVisible = !_isLocalPasswordVisible);
                    },
                  ),
                ),
                obscureText: !_isLocalPasswordVisible,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceDatabaseSection() {
    return _buildSection(
      title: 'Source Database',
      subtitle: 'ORIGIN SOURCE',
      icon: Icons.cloud,
      color: Colors.blue,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _sourceHostController,
                decoration: const InputDecoration(
                  labelText: 'Hostname',
                  prefixIcon: Icon(Icons.dns),
                ),
                validator: (v) => v!.isEmpty ? 'กรุณากรอก Hostname' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _sourcePortController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'กรุณากรอก Port' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _sourceDatabaseController,
          decoration: const InputDecoration(
            labelText: 'Database Name',
            prefixIcon: Icon(Icons.dataset),
          ),
          validator: (v) => v!.isEmpty ? 'กรุณากรอก Database Name' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _sourceUsernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'กรุณากรอก Username' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _sourcePasswordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isSourcePasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() =>
                          _isSourcePasswordVisible = !_isSourcePasswordVisible);
                    },
                  ),
                ),
                obscureText: !_isSourcePasswordVisible,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNhsoApiSection() {
    return _buildSection(
      title: 'FastAPI Integration Settings',
      subtitle: 'SSO TOKEN CONFIGURATION',
      icon: Icons.api,
      color: Colors.purple,
      children: [
        TextFormField(
          controller: _nhsoApiUrlController,
          decoration: const InputDecoration(
            labelText: 'API Endpoint URL',
            prefixIcon: Icon(Icons.link),
          ),
          validator: (v) => v!.isEmpty ? 'กรุณากรอก API URL' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nhsoTokenHeaderController,
          decoration: const InputDecoration(
            labelText: 'Token Header Name',
            prefixIcon: Icon(Icons.label),
          ),
          validator: (v) => v!.isEmpty ? 'กรุณากรอก Token Header' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nhsoAccessTokenController,
          decoration: InputDecoration(
            labelText: 'SSO Access Token',
            prefixIcon: const Icon(Icons.vpn_key),
            suffixIcon: IconButton(
              icon: Icon(
                  _isTokenVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() => _isTokenVisible = !_isTokenVisible);
              },
            ),
          ),
          obscureText: !_isTokenVisible,
          validator: (v) => v!.isEmpty ? 'กรุณากรอก Access Token' : null,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isTesting ? null : _testConnections,
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('ทดสอบการเชื่อมต่อ'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('บันทึกการตั้งค่า'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _localHostController.dispose();
    _localPortController.dispose();
    _localDatabaseController.dispose();
    _localUsernameController.dispose();
    _localPasswordController.dispose();
    _sourceHostController.dispose();
    _sourcePortController.dispose();
    _sourceDatabaseController.dispose();
    _sourceUsernameController.dispose();
    _sourcePasswordController.dispose();
    _nhsoApiUrlController.dispose();
    _nhsoTokenHeaderController.dispose();
    _nhsoAccessTokenController.dispose();
    super.dispose();
  }
}
