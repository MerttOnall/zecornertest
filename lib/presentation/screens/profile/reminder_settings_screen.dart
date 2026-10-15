import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/services/app_reminder_catalog.dart';
import 'package:zecorner/core/services/local_device_notification_service.dart';

/// Uygulama hatırlatıcılarını açıp kapatma ve önizleme.
class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final Map<String, bool> _enabled = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final def in AppReminderCatalog.definitions) {
        _enabled[def.key] = prefs.getBool(def.prefKey) ?? def.defaultEnabled;
      }
      _loading = false;
    });
  }

  Future<void> _setEnabled(String key, bool value) async {
    final def = AppReminderCatalog.byKey(key);
    if (def == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(def.prefKey, value);
    if (!mounted) return;
    setState(() => _enabled[key] = value);
    await LocalDeviceNotificationService.instance.syncAppRemindersFromPreferences();
  }

  Future<void> _preview(String key) async {
    try {
      await LocalDeviceNotificationService.instance.showReminderPreview(key);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Örnek bildirim gönderildi — üst çubuğu veya bildirim merkezini kontrol edin.',
          ),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Önizleme başarısız: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Hatırlatıcılar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE53935),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  'Açtığınız hatırlatıcılar giriş yaptığınız sürece telefonunuza bildirim olarak gider. İstediğiniz kombinasyonu seçebilirsiniz.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                ...AppReminderCatalog.definitions.map((def) {
                  final on = _enabled[def.key] ?? def.defaultEnabled;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            thumbIcon: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            activeTrackColor: const Color(0xFFE53935)
                                .withValues(alpha: 0.55),
                            title: Text(
                              def.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    def.body,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    def.scheduleLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            value: on,
                            onChanged: (v) => _setEnabled(def.key, v),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _preview(def.key),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 18,
                                color: Color(0xFFE53935),
                              ),
                              label: const Text(
                                'Örnek göster',
                                style: TextStyle(color: Color(0xFFE53935)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
