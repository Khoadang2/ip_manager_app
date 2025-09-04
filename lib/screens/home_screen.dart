import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'device_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> devices = [];

  String _filterType = "all";
  String _search = "";
  String _statFilter = "all";

  final TextEditingController _rangeCtrl = TextEditingController(text: "");
  final TextEditingController _searchCtrl = TextEditingController();

  bool _scanning = false;
  bool _auto = false;
  Timer? _autoTimer;

  int? _sortColumnIndex;
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _rangeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ===== API =====
  Future<void> _loadDevices() async {
    try {
      final list = await ApiService.getDevices();
      if (!mounted) return;
      setState(() {
        devices = (list is List)
            ? List<Map<String, dynamic>>.from(list)
            : <Map<String, dynamic>>[];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => devices = []);
    }
  }

  Future<void> _scanNetwork() async {
    setState(() => _scanning = true);
    try {
      final list = await ApiService.scanNetwork(_rangeCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        devices = (list is List)
            ? List<Map<String, dynamic>>.from(list)
            : <Map<String, dynamic>>[];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => devices = []);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  // ====== Auto refresh ======
  void _toggleAuto() {
    setState(() => _auto = !_auto);
    _autoTimer?.cancel();
    if (_auto) {
      _autoTimer =
          Timer.periodic(const Duration(seconds: 15), (_) => _scanNetwork());
    }
  }

  // ===== UI helpers =====
  Color _typeColor(String type) {
    switch (type) {
      case 'server':
        return const Color(0xFFE74C3C);
      case 'wifi':
        return const Color(0xFF3498DB);
      case 'printer':
        return const Color(0xFF2ECC71);
      case 'att':
        return const Color(0xFFE67E22);
      case 'andong':
        return const Color(0xFF9B59B6);
      case 'website':
        return const Color(0xFF3D6164);
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  Widget _typeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _typeColor(type),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // ===== thống kê =====
  int get _allTotal => devices.length;
  int get _allOnline => devices
      .where((d) => ((d["status"] is bool) ? d["status"] : d["status"] == 1))
      .length;
  int get _allOffline => _allTotal - _allOnline;

  int get _viewTotal => _filtered().length;
  int get _viewOnline => _filtered()
      .where((d) => ((d["status"] is bool) ? d["status"] : d["status"] == 1))
      .length;
  int get _viewOffline => _viewTotal - _viewOnline;

  // logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("user");
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ====== Lọc, tìm kiếm, trạng thái ======
  List<Map<String, dynamic>> _filtered() {
    var list = devices.where((d) {
      final type = (d["type"] ?? "").toString();

      final matchType = _filterType == "all"
          ? true
          : (_filterType == "other"
          ? !["server", "wifi", "printer", "att", "andong", "website"].contains(type)
          : type == _filterType);

      final text = _search.trim().toLowerCase();
      final matchSearch = text.isEmpty ||
          ((d["name"] ?? "").toString().toLowerCase().contains(text)) ||
          ((d["ip"] ?? "").toString().toLowerCase().contains(text));

      final s = (d["status"] is bool)
          ? (d["status"] == true ? 1 : 0)
          : (d["status"] ?? 0);
      final matchStat = _statFilter == "all" ||
          (_statFilter == "online" && s == 1) ||
          (_statFilter == "offline" && s == 0);

      return matchType && matchSearch && matchStat;
    }).toList();

    int cmp(String field, a, b) {
      final v1 = (a[field] ?? "").toString().toLowerCase();
      final v2 = (b[field] ?? "").toString().toLowerCase();
      return v1.compareTo(v2);
    }

    if (_sortColumnIndex != null) {
      switch (_sortColumnIndex) {
        case 0: // status
          list.sort((a, b) {
            final sa = (a["status"] is bool)
                ? (a["status"] ? 1 : 0)
                : a["status"] ?? 0;
            final sb = (b["status"] is bool)
                ? (b["status"] ? 1 : 0)
                : b["status"] ?? 0;
            return _sortAsc ? sa.compareTo(sb) : sb.compareTo(sa);
          });
          break;
        case 1: // name
          list.sort((a, b) => _sortAsc ? cmp("name", a, b) : cmp("name", b, a));
          break;
        case 2: // ip
          list.sort((a, b) => _sortAsc ? cmp("ip", a, b) : cmp("ip", b, a));
          break;
        case 3: // type
          list.sort((a, b) => _sortAsc ? cmp("type", a, b) : cmp("type", b, a));
          break;
        case 4: // dep
          list.sort((a, b) => _sortAsc ? cmp("dep", a, b) : cmp("dep", b, a));
          break;
        case 5: // note
          list.sort((a, b) => _sortAsc ? cmp("note", a, b) : cmp("note", b, a));
          break;
      }
    }
    return list;
  }

  // ===== Drawer bộ lọc =====
  Drawer _filterDrawer() {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text("Bộ lọc",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeviceForm()),
                  );
                  _loadDevices();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text("Thêm thiết bị"),
              ),
              const Divider(height: 30),

              const Text("Lọc theo loại",
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _filterType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "all", child: Text("Tất cả")),
                  DropdownMenuItem(value: "server", child: Text("Server")),
                  DropdownMenuItem(value: "wifi", child: Text("Wifi")),
                  DropdownMenuItem(value: "printer", child: Text("Printer")),
                  DropdownMenuItem(value: "att", child: Text("Máy chấm công")),
                  DropdownMenuItem(value: "andong", child: Text("QC An Dong")),
                  DropdownMenuItem(value: "website", child: Text("WebSite")),
                  DropdownMenuItem(value: "other", child: Text("Khác")),
                ],
                onChanged: (v) {
                  setState(() {
                    _filterType = v ?? "all";
                  });

                  // 🔹 Đóng Drawer trước
                  Navigator.pop(context);

                  // 🔹 Sau khi Drawer đóng thì mới quét mạng
                  Future.delayed(const Duration(milliseconds: 300), () async {
                    await _scanNetwork();
                  });
                },

              ),
              const SizedBox(height: 20),

              const Text("Phạm vi quét (ví dụ: 192.168.79.1)",
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: _rangeCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _scanning ? null : _scanNetwork,
                child: Text(_scanning ? "Đang quét..." : "Quét mạng (Scan)"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== bảng dữ liệu =====
  Widget _table() {
    final list = _filtered();
    DataColumn col(String label, int index, {double? width}) {
      return DataColumn(
        label: SizedBox(
          width: width,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        onSort: (i, asc) {
          setState(() {
            _sortColumnIndex = index;
            _sortAsc = asc;
          });
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: DataTable(
          sortAscending: _sortAsc,
          sortColumnIndex: _sortColumnIndex,
          columnSpacing: 10,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 42,
          columns: [
            col("TT", 0, width: 40),
            col("Tên", 1, width: 120),
            col("IP", 2, width: 80),
            col("Loại", 3, width: 60),
            col("Đơn vị", 4, width: 120),
            col("Ghi chú", 5, width: 120),
            const DataColumn(label: Text("⚙", style: TextStyle(fontSize: 12))),
          ],
          rows: list.map((d) {
            final s = (d["status"] is bool) ? d["status"] : d["status"] == 1;
            return DataRow(cells: [
              DataCell(Row(
                children: [
                  Icon(Icons.circle,
                      size: 10, color: s ? Colors.green : Colors.red),
                  const SizedBox(width: 2),
                  Text(s ? "On" : "Off",
                      style: const TextStyle(fontSize: 11)),
                ],
              )),
              DataCell(Text(d["name"] ?? "",
                  style: const TextStyle(fontSize: 12))),
              DataCell(Text(
                "${d["ip"]}${d["port"] != null && d["port"].toString().isNotEmpty ? ":${d["port"]}" : ""}",
                style: const TextStyle(fontFamily: "monospace", fontSize: 11),
              )),
              DataCell(_typeChip(d["type"] ?? "other")),
              DataCell(
                  Text(d["dep"] ?? "-", style: const TextStyle(fontSize: 11))),
              DataCell(
                  Text(d["note"] ?? "", style: const TextStyle(fontSize: 11))),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DeviceForm(device: d)),
                      );
                      _loadDevices();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Xác nhận"),
                          content:
                          const Text("Bạn có chắc muốn xóa thiết bị này không?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Không"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Có"),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ApiService.deleteDevice(d["id"]);
                        _loadDevices();
                      }
                    },
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ===== Overlay loading =====
  Widget _loadingOverlay() {
    if (!_scanning) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: _scanning ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.cyan,
            strokeWidth: 4,
          ),
        ),
      ),
    );
  }

  // ===== Giao diện chính =====
  @override
  Widget build(BuildContext context) {
    final list = _filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý IP cố định"),
        actions: [
          TextButton.icon(
            onPressed: _toggleAuto,
            icon: Icon(
              _auto ? Icons.autorenew : Icons.pause_circle,
              color: Colors.white,
            ),
            label: Text(
              _auto ? "Auto: Bật" : "Auto: Tắt",
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      drawer: _filterDrawer(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm theo tên hoặc IP...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                  ),
                  onChanged: (val) {
                    setState(() => _search = val);
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _statCard("Tổng ($_allTotal)", _viewTotal, Colors.white, () {
                      setState(() => _statFilter = "all");
                      _scanNetwork();
                    }),
                    const SizedBox(width: 6),
                    _statCard("Online ($_allOnline)", _viewOnline, Colors.green,
                            () {
                          setState(() => _statFilter = "online");
                        }),
                    const SizedBox(width: 6),
                    _statCard("Offline ($_allOffline)", _viewOffline, Colors.red,
                            () {
                          setState(() => _statFilter = "offline");
                        }),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text("Không có dữ liệu"))
                      : SingleChildScrollView(child: _table()),
                ),
              ],
            ),
          ),
          _loadingOverlay(), // ✅ overlay mờ + vòng xoay cyan
        ],
      ),
    );
  }

  // ===== Card thống kê =====
  Widget _statCard(String title, int value, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x1106B6D4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x2206B6D4)),
          ),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 3),
              Text(
                "$value",
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
