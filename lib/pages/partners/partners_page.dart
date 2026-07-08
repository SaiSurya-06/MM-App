import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/partner_sync_provider.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/toast_notification.dart';
import '../../core/utils/currency_formatter.dart';
import '../accounts/account_card.dart';
import '../transactions/transaction_list_item.dart';
import '../../core/utils/share_code_encoder.dart';
import '../../models/transaction.dart';


const String _gasCodeTemplate = '''// Google Apps Script - Money Manager Partner Sync
// Deploy as: Web App | Execute as: Me | Who has access: Anyone

function doGet(e) {
  var params = e.parameter;
  var action = params.action;
  
  if (action === "test") {
    return ContentService.createTextOutput("ok").setMimeType(ContentService.MimeType.TEXT);
  }
  
  var sheet = getOrCreateSheet();
  
  if (action === "get") {
    var key = params.key;
    var val = getValueByKey(sheet, key);
    if (val === null) {
      return ContentService.createTextOutput("404").setMimeType(ContentService.MimeType.TEXT);
    }
    return ContentService.createTextOutput(val).setMimeType(ContentService.MimeType.TEXT);
  }
  
  if (action === "set_chunk") {
    var key = params.key;
    var index = parseInt(params.index);
    var total = parseInt(params.total);
    var val = params.val;
    
    // Store chunk
    var chunkKey = key + "_chunk_" + index;
    setValueByKey(sheet, chunkKey, val);
    
    // Check if all chunks are present
    var allChunks = [];
    var missing = false;
    for (var i = 0; i < total; i++) {
      var cVal = getValueByKey(sheet, key + "_chunk_" + i);
      if (cVal === null) {
        missing = true;
        break;
      }
      allChunks.push(cVal);
    }
    
    if (!missing) {
      // Assemble and save
      var fullVal = allChunks.join("");
      setValueByKey(sheet, key, fullVal);
      
      // Clean up chunk rows
      for (var i = 0; i < total; i++) {
        deleteRowByKey(sheet, key + "_chunk_" + i);
      }
      return ContentService.createTextOutput("assembled").setMimeType(ContentService.MimeType.TEXT);
    }
    
    return ContentService.createTextOutput("chunk_received").setMimeType(ContentService.MimeType.TEXT);
  }
  
  return ContentService.createTextOutput("error: unknown action").setMimeType(ContentService.MimeType.TEXT);
}

function getOrCreateSheet() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("SyncData");
  if (!sheet) {
    sheet = ss.insertSheet("SyncData");
    sheet.appendRow(["Key", "Value", "UpdatedAt"]);
    sheet.setFrozenRows(1);
    sheet.getRange("B:B").setNumberFormat("@");
  }
  return sheet;
}

function getValueByKey(sheet, key) {
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] == key) {
      return data[i][1];
    }
  }
  return null;
}

function setValueByKey(sheet, key, value) {
  var data = sheet.getDataRange().getValues();
  var dateStr = new Date().toISOString();
  var found = false;
  
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] == key) {
      if (!found) {
        var cell = sheet.getRange(i + 1, 2);
        cell.setValue("'" + value);
        sheet.getRange(i + 1, 3).setValue(dateStr);
        found = true;
      } else {
        sheet.deleteRow(i + 1);
        data.splice(i, 1);
        i--;
      }
    }
  }
  if (!found) {
    sheet.appendRow([key, "'" + value, dateStr]);
  }
}

function deleteRowByKey(sheet, key) {
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] == key) {
      sheet.deleteRow(i + 1);
      data.splice(i, 1);
      i--;
    }
  }
}''';

class PartnersPage extends ConsumerStatefulWidget {
  const PartnersPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends ConsumerState<PartnersPage> with SingleTickerProviderStateMixin {
  int _onboardingTabIndex = 0; // 0 = Host, 1 = Join
  int _dashboardTabIndex = 0; // 0 = Accounts, 1 = Ledger

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isTestingConnection = false;
  bool _testingSuccess = false;
  String? _generatedInviteCode;
  String _searchQuery = '';

  late AnimationController _syncIconController;

  @override
  void initState() {
    super.initState();
    _syncIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _joinCodeController.dispose();
    _searchController.dispose();
    _syncIconController.dispose();
    super.dispose();
  }

  Future<void> _copyScript() async {
    try {
      final script = await rootBundle.loadString('assets/gas_sync_template.js');
      await Clipboard.setData(ClipboardData(text: script));
      if (mounted) {
        ToastNotification.show(context, 'Apps Script template copied to clipboard!');
      }
    } catch (e) {
      await Clipboard.setData(const ClipboardData(text: _gasCodeTemplate));
      if (mounted) {
        ToastNotification.show(context, 'Apps Script template copied to clipboard! (Fallback)');
      }
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ToastNotification.show(context, 'Please input your Web App URL.', isError: true);
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _testingSuccess = false;
    });

    final success = await ref.read(partnerSyncProvider.notifier).testConnection(url);

    setState(() {
      _isTestingConnection = false;
      _testingSuccess = success;
    });

    if (success) {
      ToastNotification.show(context, 'Connection successful! Web App is active.');
    } else {
      ToastNotification.show(context, 'Connection failed. Please check the URL and script deployment.', isError: true);
    }
  }

  Future<void> _startHosting() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ToastNotification.show(context, 'Please enter the Web App URL first.', isError: true);
      return;
    }

    final code = await ref.read(partnerSyncProvider.notifier).generateInviteCode(url);
    if (code != null) {
      setState(() {
        _generatedInviteCode = code;
      });
      ToastNotification.show(context, 'Room generated successfully! Share the invitation.');
    }
  }

  Future<void> _joinRoom() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) {
      ToastNotification.show(context, 'Please paste the invitation code.', isError: true);
      return;
    }

    final success = await ref.read(partnerSyncProvider.notifier).joinWithInviteCode(code);
    if (success) {
      ToastNotification.show(context, 'Successfully joined the partner sharing room!');
    } else {
      final error = ref.read(partnerSyncProvider).errorMessage ?? 'Failed to connect. Please try again.';
      ToastNotification.show(context, error, isError: true);
    }
  }

  Future<void> _scanQrCode() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ToastNotification.show(context, 'Camera permission is required to scan QR codes.', isError: true);
      }
      return;
    }

    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
        );
      },
    );

    if (code != null && code.isNotEmpty) {
      _joinCodeController.text = code;
      setState(() {});
      _joinRoom();
    }
  }

  Future<void> _manualSync() async {
    _syncIconController.repeat();
    final success = await ref.read(partnerSyncProvider.notifier).syncNow();
    _syncIconController.stop();

    if (success) {
      ToastNotification.show(context, 'Data synced successfully.');
    } else {
      final error = ref.read(partnerSyncProvider).errorMessage ?? 'Sync failed.';
      ToastNotification.show(context, error, isError: true);
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Sharing?'),
        content: const Text('This will delete the partner connection and clear cached partner data from this device. Your local data will remain unaffected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), minimumSize: const Size(80, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(partnerSyncProvider.notifier).disconnect();
      setState(() {
        _generatedInviteCode = null;
        _urlController.clear();
        _joinCodeController.clear();
      });
      ToastNotification.show(context, 'Disconnected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(partnerSyncProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D14) : const Color(0xFFF5F5F7);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A26);
    final subTextColor = isDark ? const Color(0xFFB0B0C0) : const Color(0xFF6C6C7D);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Partner Sharing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: syncState.isConnected
              ? _buildActiveLayout(syncState, isDark, cardBg, textColor, subTextColor)
              : _buildOnboardingLayout(isDark, cardBg, textColor, subTextColor),
        ),
      ),
    );
  }

  Widget _buildOnboardingLayout(bool isDark, Color cardBg, Color textColor, Color subTextColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Onboarding Banner Card
          GlassmorphismCard(
            padding: const EdgeInsets.all(20),
            color: isDark ? const Color(0xFF1E1E2E).withOpacity(0.4) : Colors.white.withOpacity(0.8),
            borderColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_alt, color: Color(0xFFE53935), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Share Finances Safely',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Track joint transactions, account balances, and credit card pending payments with your partner in real-time. Only one person does the spreadsheet setup!',
                  style: TextStyle(
                    fontSize: 13,
                    color: subTextColor,
                    height: 1.4,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Data Sharing & Security Diagram Card
          _buildSecurityDiagram(isDark, textColor, subTextColor),
          const SizedBox(height: 20),

          // Custom Pill Selector
          _buildPillTabBar(
            selectedIndex: _onboardingTabIndex,
            tabs: const ['Set Up as Host', 'Join with Code'],
            onTap: (index) {
              setState(() {
                _onboardingTabIndex = index;
              });
            },
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Tab content
          _onboardingTabIndex == 0
              ? _buildHostSetupTab(isDark, cardBg, textColor, subTextColor)
              : _buildJoinTab(isDark, cardBg, textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _buildPillTabBar({
    required int selectedIndex,
    required List<String> tabs,
    required ValueChanged<int> onTap,
    required bool isDark,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161625) : const Color(0xFFE0E0E6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE53935) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFB0B0C0) : const Color(0xFF6C6C7D)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHostSetupTab(bool isDark, Color cardBg, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Deploy Apps Script (Google Sheets)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a blank Google Sheet, click Extensions → Apps Script, delete any placeholder code, and paste our script template below.',
          style: TextStyle(fontSize: 12, color: subTextColor, height: 1.4),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _copyScript,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy Script Template'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFE0E0E6),
            foregroundColor: textColor,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          '2. Deploy as Web App',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        Text(
          'In Apps Script, click Deploy → New Deployment.\n• Select type: Web App\n• Execute as: Me (your email)\n• Who has access: Anyone\nCopy the Web App URL generated at the end.',
          style: TextStyle(fontSize: 12, color: subTextColor, height: 1.4),
        ),
        const SizedBox(height: 20),

        Text(
          '3. Link to Money Manager',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          onChanged: (val) {
            if (_testingSuccess) {
              setState(() {
                _testingSuccess = false;
              });
            }
          },
          decoration: InputDecoration(
            hintText: 'https://script.google.com/macros/s/.../exec',
            prefixIcon: const Icon(Icons.link),
            suffixIcon: _testingSuccess
                ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                : null,
          ),
          style: TextStyle(color: textColor, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isTestingConnection ? null : _testConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935), width: 1),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isTestingConnection
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE53935)))
                    : const Text('Verify Connection'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _testingSuccess ? _startHosting : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Hosting'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJoinTab(bool isDark, Color cardBg, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect to Shared Sheets',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        Text(
          'Paste the Room Invitation code shared by your partner below. This will automatically resolve their spreadsheet URL and join the room.',
          style: TextStyle(fontSize: 12, color: subTextColor, height: 1.4),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _joinCodeController,
          maxLines: 3,
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Paste invite code here...',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 30.0),
              child: Icon(Icons.vpn_key),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFE53935)),
              onPressed: _scanQrCode,
              tooltip: 'Scan QR Code',
            ),
          ),
          style: TextStyle(color: textColor, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _joinCodeController.text.isNotEmpty ? _joinRoom : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Connect & Sync'),
        ),
      ],
    );
  }

  Widget _buildActiveLayout(PartnerSyncState syncState, bool isDark, Color cardBg, Color textColor, Color subTextColor) {
    // If hosting and partner has not joined yet, show the onboarding room info
    if (syncState.mySlot == 'A' && syncState.partnerName == 'Waiting...') {
      final localInviteCode = _generatedInviteCode ?? 
          ShareCodeEncoder.encode({
            'url': syncState.webAppUrl,
            'room': syncState.roomCode,
            'slot': 'A',
            if (syncState.syncPassword != null) 'password': syncState.syncPassword,
            if (syncState.syncSalt != null) 'salt': syncState.syncSalt,
          });

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_done_rounded, color: Colors.green, size: 60),
            const SizedBox(height: 12),
            Text(
              'Room Connection Ready! 🚀',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Google Sheets sync server is online. Ask your partner to open the app, tap Join Room, and scan/paste the details below.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: subTextColor, height: 1.4),
            ),
            const SizedBox(height: 24),

            // QR Code Card
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: localInviteCode,
                  version: QrVersions.auto,
                  size: 180.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Short/Long Invite code copy
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: localInviteCode));
                ToastNotification.show(context, 'Invite Code copied to clipboard.');
              },
              borderRadius: BorderRadius.circular(12),
              child: GlassmorphismCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? const Color(0xFF161625) : const Color(0xFFEBEBEF),
                child: Row(
                  children: [
                    const Icon(Icons.copy_rounded, size: 18, color: Color(0xFFE53935)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invite Code', style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            localInviteCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                Share.share(localInviteCode, subject: 'Join my Money Manager Room');
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Code'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (syncState.isSyncing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE53935)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: Color(0xFFE53935)),
                    onPressed: _manualSync,
                    tooltip: 'Check if partner has joined',
                  ),
                const SizedBox(width: 10),
                Text(
                  'Waiting for partner to join...',
                  style: TextStyle(fontSize: 13, color: subTextColor, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            if (syncState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  syncState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFE53935), fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: _disconnect,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
              child: const Text('Disconnect Room'),
            ),
          ],
        ),
      );
    }

    // Otherwise, we are fully connected and have partner info
    return Column(
      children: [
        // Sync Status Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: syncState.isSyncing ? Colors.amber : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                syncState.isSyncing 
                    ? 'Syncing...' 
                    : 'Linked with ${syncState.partnerName}',
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: textColor
                ),
              ),
              const Spacer(),
              IconButton(
                icon: RotationTransition(
                  turns: _syncIconController,
                  child: const Icon(Icons.sync),
                ),
                color: const Color(0xFFE53935),
                onPressed: syncState.isSyncing ? null : _manualSync,
              ),
              IconButton(
                icon: const Icon(Icons.power_settings_new),
                color: const Color(0xFFE53935),
                onPressed: _disconnect,
              ),
            ],
          ),
        ),

        if (syncState.isSyncing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF1E1E30), const Color(0xFF2D2D44)] 
                      : [Colors.grey[100]!, Colors.grey[200]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          syncState.syncStatusMessage ?? 'Syncing shared ledger...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(syncState.syncProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE53935),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: 0.0,
                        end: syncState.syncProgress,
                      ),
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: isDark 
                              ? Colors.white.withOpacity(0.08) 
                              : Colors.black.withOpacity(0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Conflict warning banner
        if (syncState.conflicts.isNotEmpty)
          _buildConflictBanner(context, syncState, isDark, textColor, subTextColor),

        // Sticky Note: Manual Sync Reminder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFFE53935).withOpacity(0.08) 
                  : const Color(0xFFE53935).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE53935).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFE53935),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Background automatic sync has been disabled to prevent distracting dashboard refreshes. To fetch or send new updates, simply tap the Sync icon (🔄) in the status bar above.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.85),
                      height: 1.4,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab Selector for Dashboard
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildPillTabBar(
            selectedIndex: _dashboardTabIndex,
            tabs: const ['Accounts', 'Transactions Ledger'],
            onTap: (index) {
              setState(() {
                _dashboardTabIndex = index;
              });
            },
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: _dashboardTabIndex == 0
              ? _buildAccountsGrid(syncState, textColor, subTextColor)
              : _buildTransactionsLedger(syncState, isDark, textColor, subTextColor),
        ),
      ],
    );
  }

  Widget _buildAccountsGrid(PartnerSyncState syncState, Color textColor, Color subTextColor) {
    if (syncState.partnerAccounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No shared accounts found.',
              style: TextStyle(color: subTextColor),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: syncState.partnerAccounts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ((MediaQuery.of(context).size.width - 32 - 12) / 2) / 172.0,
      ),
      itemBuilder: (context, index) {
        final account = syncState.partnerAccounts[index];
        return AccountCard(
          account: account,
          currency: syncState.partnerCurrency,
          onTap: () {
            context.push('/partner-sharing/account-detail', extra: account);
          },
        );
      },
    );
  }

  Widget _buildTransactionsLedger(PartnerSyncState syncState, bool isDark, Color textColor, Color subTextColor) {
    if (syncState.partnerTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No transaction history synced.',
              style: TextStyle(color: subTextColor),
            ),
          ],
        ),
      );
    }

    // Filter transactions locally
    final filtered = syncState.partnerTransactions.where((tx) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final titleMatch = tx.title.toLowerCase().contains(q);
      final noteMatch = tx.note?.toLowerCase().contains(q) ?? false;
      final accountMatch = tx.accountName.toLowerCase().contains(q);
      final categoryMatch = tx.categoryName.toLowerCase().contains(q);
      return titleMatch || noteMatch || accountMatch || categoryMatch;
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search partner transactions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(color: textColor, fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No matching transactions found.', style: TextStyle(color: subTextColor)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    
                    // Re-package partner transaction to standard transaction model
                    final modelTx = Transaction(
                      title: tx.title,
                      amount: tx.amount,
                      type: tx.type,
                      date: tx.date,
                      note: tx.note,
                      recurrence: tx.recurrence,
                      isPrivate: false,
                      accountId: 0,
                      categoryId: 0,
                      createdAt: tx.date,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TransactionListItem(
                        transaction: modelTx,
                        categoryName: tx.categoryName,
                        categoryColorHex: tx.categoryColor,
                        categoryIconKey: tx.categoryIcon,
                        accountName: tx.accountName,
                        currency: syncState.partnerCurrency,
                        onTap: () => _showTransactionDetails(tx, syncState.partnerCurrency),
                        onLongPress: () => _showTransactionDetails(tx, syncState.partnerCurrency),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showTransactionDetails(PartnerTransaction tx, String currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '${tx.type == 'income' ? '+' : '-'}${CurrencyFormatter.format(tx.amount, currency)}', valueColor: tx.type == 'income' ? Colors.green : const Color(0xFFE53935)),
            _buildDetailRow('Account', tx.accountName),
            _buildDetailRow('Category', tx.categoryName),
            _buildDetailRow('Date', tx.date.toIso8601String().substring(0, 10)),
            if (tx.note != null && tx.note!.isNotEmpty)
              _buildDetailRow('Note', tx.note!),
            if (tx.recurrence != 'none')
              _buildDetailRow('Recurrence', tx.recurrence),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: valueColor != null ? FontWeight.bold : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(
    BuildContext context,
    PartnerSyncState syncState,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB300), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Conflict Detected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${syncState.conflicts.length} account(s) have conflicting details.',
                  style: TextStyle(
                    fontSize: 12,
                    color: subTextColor,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black,
              minimumSize: const Size(70, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showConflictResolverDialog(context, syncState),
            child: const Text(
              'Resolve',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }

  void _showConflictResolverDialog(BuildContext context, PartnerSyncState syncState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            if (syncState.conflicts.isEmpty) {
              Navigator.pop(context);
              return const SizedBox.shrink();
            }
            final conflict = syncState.conflicts.first;
            
            final localBal = conflict.localData['balance'] as double? ?? 0.0;
            final partnerBal = conflict.partnerData['balance'] as double? ?? 0.0;
            final localLimit = conflict.localData['limit_amount'] as double?;
            final partnerLimit = conflict.partnerData['limit_amount'] as double?;
            
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              title: Text(
                'Resolve Conflict: ${conflict.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This account has different values on both devices. Choose which version to keep:',
                    style: TextStyle(fontSize: 13, height: 1.4, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 20),
                  
                  // Option 1: Keep Mine
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(partnerSyncProvider.notifier).resolveConflict(conflict, true);
                      ToastNotification.show(context, 'Resolved: Kept your local version.');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFE53935).withOpacity(0.04),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Keep My Version', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE53935), fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text('Balance: ${CurrencyFormatter.format(localBal, syncState.partnerCurrency)}', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                                if (localLimit != null)
                                  Text('Limit: ${CurrencyFormatter.format(localLimit, syncState.partnerCurrency)}', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFFE53935)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Option 2: Keep Partner's
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(partnerSyncProvider.notifier).resolveConflict(conflict, false);
                      ToastNotification.show(context, 'Resolved: Kept partner\'s version.');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.green.withOpacity(0.04),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Keep ${syncState.partnerName}\'s Version', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green, fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text('Balance: ${CurrencyFormatter.format(partnerBal, syncState.partnerCurrency)}', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                                if (partnerLimit != null)
                                  Text('Limit: ${CurrencyFormatter.format(partnerLimit, syncState.partnerCurrency)}', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Widget _buildSecurityDiagram(bool isDark, Color textColor, Color subTextColor) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
      borderColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Data Sharing & Security',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor, fontFamily: 'Inter'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Visual block diagram
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDiagramNode('My Device', Icons.phone_android),
                Icon(Icons.swap_horiz, color: Colors.grey.withOpacity(0.6), size: 20),
                _buildDiagramNode('Secure Cloud\n(Apps Script)', Icons.cloud_outlined),
                Icon(Icons.swap_horiz, color: Colors.grey.withOpacity(0.6), size: 20),
                _buildDiagramNode('Partner', Icons.people_outline),
              ],
            ),
          ),
          
          const SizedBox(height: 14),
          Text(
            '• Non-Private Data Only: Only accounts and transactions NOT marked as private are shared.',
            style: TextStyle(fontSize: 11.5, color: subTextColor, height: 1.4, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 4),
          Text(
            '• Secure Encryption: Sync credentials, keys, and connection details are stored using secure storage.',
            style: TextStyle(fontSize: 11.5, color: subTextColor, height: 1.4, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramNode(String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFE53935)),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
      ],
    );
  }
}
