class AppValidators {
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a price';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (double.parse(value) < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }

  static String? stockCount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Masukkan jumlah stok';
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 'Stok harus berupa angka bulat';
    }
    if (parsed < 0) {
      return 'Stok tidak boleh negatif';
    }
    return null;
  }
}
