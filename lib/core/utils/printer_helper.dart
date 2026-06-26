import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';

class EscPos {
  static const List<int> init = [0x1B, 0x40];
  static const List<int> alignCenter = [0x1B, 0x61, 0x01];
  static const List<int> alignLeft = [0x1B, 0x61, 0x00];
  static const List<int> alignRight = [0x1B, 0x61, 0x02];
  static const List<int> boldOn = [0x1B, 0x45, 0x01];
  static const List<int> boldOff = [0x1B, 0x45, 0x00];
  static const List<int> textNormal = [0x1D, 0x21, 0x00];
  static const List<int> textLarge = [0x1D, 0x21, 0x11];
  static const List<int> lineFeed = [0x0A];
}

class PrinterHelper {
  // Singleton
  static final PrinterHelper _instance = PrinterHelper._internal();
  factory PrinterHelper() => _instance;
  PrinterHelper._internal();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<bool> checkPermission() async {
    // Request Bluetooth and Location permissions
    // Android 12+ needs BLUETOOTH_SCAN, BLUETOOTH_CONNECT
    // Older Android needs BLUETOOTH, BLUETOOTH_ADMIN, ACCESS_FINE_LOCATION

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<List<BluetoothInfo>> getBondedDevices() async {
    try {
      final List<BluetoothInfo> list =
          await PrintBluetoothThermal.pairedBluetooths;
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      _isConnected = result;
      return result;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      _isConnected =
          !result; // If disconnected successfully, isConnected is false
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> printText(String text) async {
    if (!_isConnected) return;

    // Simple text printing
    // We can use bytes for advanced formatting
    // But plugin supports basic text or bytes

    // Checking battery or connection status
    final bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      // Plugin allows sending bytes. We need ESC/POS commands for text.
      // However, the plugin might have helper.
      // Looking at doc, `writeBytes` or `writeString`?
      // The plugin `print_bluetooth_thermal` mainly exposes `writeBytes`.
      // We need a generator. `esc_pos_utils` is common but not requested.
      // But wait, `print_bluetooth_thermal` example often uses `capability_profile` and `generator`.
      // I don't have `esc_pos_utils` or similar in my pubspec.
      // The user requested `print_bluetooth_thermal`.
      // Let's assume we can send raw string bytes or use a simple helper.
      // Actually without `esc_pos_utils`, formatting is hard.
      // I will try to use `esc_pos_utils_plus` or similar if I can add it, but user gave specific packages.
      // Wait, user allowed "use required plugins".
      // "suggest barcode scanner ... and use required plugins".
      // So I can add `esc_pos_utils_plus`.

      // For now, I'll assume simple text printing by converting string to bytes.
      // ASCII bytes.
      List<int> bytes = text.codeUnits;
      await PrintBluetoothThermal.writeBytes(bytes);
    }
  }

  Future<void> printReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required List<Map<String, dynamic>> items,
    required double total,
    required String footer,
    String invoiceNumber = '',
    String paymentMethod = 'QRIS',
    double cashReceived = 0,
    double change = 0,
  }) async {
    if (!_isConnected) return;

    List<int> bytes = [];

    bytes += EscPos.init;

    // Shop Name
    bytes += EscPos.alignCenter;
    bytes += EscPos.boldOn;
    bytes += EscPos.textLarge;
    bytes += _textToBytes(shopName);
    bytes += EscPos.lineFeed;

    // Address & Phone
    bytes += EscPos.textNormal;
    bytes += EscPos.boldOff;
    if (address1.isNotEmpty) {
      bytes += _textToBytes(address1);
      bytes += EscPos.lineFeed;
    }
    if (address2.isNotEmpty) {
      bytes += _textToBytes(address2);
      bytes += EscPos.lineFeed;
    }
    if (phone.isNotEmpty) {
      bytes += _textToBytes(phone);
      bytes += EscPos.lineFeed;
    }

    bytes += _textToBytes('--------------------------------');
    bytes += EscPos.lineFeed;

    // Invoice number & date
    bytes += EscPos.alignLeft;
    if (invoiceNumber.isNotEmpty) {
      bytes += _textToBytes('No: $invoiceNumber');
      bytes += EscPos.lineFeed;
    }
    String formattedDate =
        DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    bytes += _textToBytes(formattedDate);
    bytes += EscPos.lineFeed;

    bytes += _textToBytes('--------------------------------');
    bytes += EscPos.lineFeed;

    bytes += _textToBytes('Item            Harga   Total');
    bytes += EscPos.lineFeed;
    bytes += _textToBytes('--------------------------------');
    bytes += EscPos.lineFeed;

    // Items
    for (var item in items) {
      String name = item['name'].toString();
      String qty = item['qty'].toString();
      String price = _fmtNum(item['price']);
      String totalItem = _fmtNum(item['total']);

      String qtyPrefix = '${qty}x ';
      int availForName = 16 - qtyPrefix.length;
      if (name.length <= availForName) {
        bytes += _textToBytes((qtyPrefix + name).padRight(16) + price.padLeft(8) + totalItem.padLeft(8));
        bytes += EscPos.lineFeed;
      } else {
        // First line: qty + first part of name + price + total on same line
        bytes += _textToBytes(qtyPrefix + name.substring(0, availForName) + price.padLeft(8) + totalItem.padLeft(8));
        bytes += EscPos.lineFeed;
        // Remaining name wraps below, indented to align with name start
        String indent = ' ' * qtyPrefix.length;
        String remaining = name.substring(availForName);
        while (remaining.isNotEmpty) {
          int take = remaining.length > 16 ? 16 : remaining.length;
          bytes += _textToBytes(indent + remaining.substring(0, take));
          bytes += EscPos.lineFeed;
          remaining = remaining.substring(take);
        }
      }
    }

    bytes += _textToBytes('--------------------------------');
    bytes += EscPos.lineFeed;

    // Total
    bytes += EscPos.alignRight;
    bytes += EscPos.boldOn;
    bytes += _textToBytes('TOTAL: Rp ${_fmtNum(total)}');
    bytes += EscPos.lineFeed;
    bytes += EscPos.boldOff;

    // Payment info
    bytes += EscPos.alignLeft;
    bytes += _textToBytes('Pembayaran: $paymentMethod');
    bytes += EscPos.lineFeed;
    if (paymentMethod == 'Tunai') {
      bytes += _textToBytes('Diterima : Rp ${_fmtNum(cashReceived)}');
      bytes += EscPos.lineFeed;
      bytes += EscPos.boldOn;
      bytes += _textToBytes('Kembalian: Rp ${_fmtNum(change)}');
      bytes += EscPos.boldOff;
      bytes += EscPos.lineFeed;
    }

    bytes += EscPos.lineFeed;

    // Footer
    bytes += EscPos.alignCenter;
    bytes += _textToBytes(footer);
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  String _fmtNum(dynamic value) {
    final num amount = value is num ? value : (num.tryParse(value.toString()) ?? 0);
    return NumberFormat('#,##0', 'id_ID').format(amount);
  }

  List<int> _textToBytes(String text) {
    return List.from(text.codeUnits);
  }
}
