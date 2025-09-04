// device_form.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DeviceForm extends StatefulWidget {
  final Map<String, dynamic>? device;
  const DeviceForm({super.key, this.device});

  @override
  State<DeviceForm> createState() => _DeviceFormState();
}

class _DeviceFormState extends State<DeviceForm> {
  final _name = TextEditingController();
  final _ip = TextEditingController();
  final _port = TextEditingController();
  final _dep = TextEditingController();
  final _note = TextEditingController();
  String _type = "server";
  bool _status = true;

  @override
  void initState() {
    super.initState();
    final d = widget.device;
    if (d != null) {
      _name.text = d["name"] ?? "";
      _ip.text = d["ip"] ?? "";
      _port.text = d["port"]?.toString() ?? "";
      _dep.text = d["dep"] ?? "";
      _note.text = d["note"] ?? "";
      _type = d["type"] ?? "server";
      _status = (d["status"] is bool) ? d["status"] : d["status"] == 1;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final userid = prefs.getString("user") ?? "MOBILE_APP";

    final data = {
      "name": _name.text.trim(),
      "type": _type,
      "ip": _ip.text.trim(),
      "port": _port.text.trim().isEmpty ? null : int.tryParse(_port.text.trim()),
      "dep": _dep.text.trim(),
      "note": _note.text.trim(),
      "status": _status ? 1 : 0,
      "userid": userid,
    };

    if (widget.device == null) {
      await ApiService.addDevice(data);
    } else {
      await ApiService.updateDevice(widget.device!["id"], data);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device == null ? "Thêm thiết bị" : "Sửa thiết bị"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView( // ✅ responsive
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight * 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _name, decoration: const InputDecoration(labelText: "Tên thiết bị")),
                const SizedBox(height: 10),
                TextField(controller: _ip, decoration: const InputDecoration(labelText: "IP")),
                const SizedBox(height: 10),
                TextField(
                  controller: _port,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Port (tùy chọn)"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: _type,
                  decoration: const InputDecoration(labelText: "Loại thiết bị"),
                  items: const [
                    DropdownMenuItem(value: "server", child: Text("Server")),
                    DropdownMenuItem(value: "wifi", child: Text("Wifi")),
                    DropdownMenuItem(value: "printer", child: Text("Printer")),
                    DropdownMenuItem(value: "att", child: Text("Máy chấm công")),
                    DropdownMenuItem(value: "andong", child: Text("QC An Dong")),
                    DropdownMenuItem(value: "website", child: Text("WebSite")),
                    DropdownMenuItem(value: "other", child: Text("Khác")),
                  ],
                  onChanged: (v) => setState(() => _type = v as String),
                ),
                const SizedBox(height: 10),
                TextField(controller: _dep, decoration: const InputDecoration(labelText: "Đơn vị")),
                const SizedBox(height: 10),
                TextField(controller: _note, decoration: const InputDecoration(labelText: "Ghi chú")),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _status,
                  title: const Text("Online"),
                  onChanged: (v) => setState(() => _status = v),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _save, child: const Text("Lưu")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
