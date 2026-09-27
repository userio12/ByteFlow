/// High-precision data byte and network throughput formatting utilities.
abstract final class ByteFormatter {
  static const int _unitStep = 1024;
  static const List<String> _byteUnits = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  static const List<String> _bitSpeedUnits = ['b/s', 'Kb/s', 'Mb/s', 'Gb/s'];
  static const List<String> _byteSpeedUnits = ['B/s', 'KB/s', 'MB/s', 'GB/s'];

  /// Formats raw [bytes] into a human-readable string with unit (e.g. `"2.45 MB"`).
  static String format(int bytes, {int decimals = 2}) {
    final (value, unit) = formatParts(bytes, decimals: decimals);
    return '$value $unit';
  }

  /// Deconstructs [bytes] into a numeric string and unit record `(value, unit)`
  /// for separate typography rendering.
  static (String value, String unit) formatParts(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return ('0', 'B');

    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= _unitStep && unitIndex < _byteUnits.length - 1) {
      size /= _unitStep;
      unitIndex++;
    }

    if (unitIndex == 0) {
      return (bytes.toString(), _byteUnits[unitIndex]);
    }

    // Format with desired decimal places, trimming trailing zeros if clean integer
    final formattedValue = size.toStringAsFixed(decimals);
    return (formattedValue, _byteUnits[unitIndex]);
  }

  /// Formats [bytesPerSecond] into throughput rate string (e.g. `"2.4 MB/s"` or `"19.2 Mb/s"`).
  static String formatSpeed(
    int bytesPerSecond, {
    bool useBits = false,
    int decimals = 1,
  }) {
    if (bytesPerSecond <= 0) {
      return useBits ? '0 b/s' : '0 B/s';
    }

    if (useBits) {
      double bits = (bytesPerSecond * 8).toDouble();
      int unitIndex = 0;
      while (bits >= 1000 && unitIndex < _bitSpeedUnits.length - 1) {
        bits /= 1000;
        unitIndex++;
      }
      return '${bits.toStringAsFixed(decimals)} ${_bitSpeedUnits[unitIndex]}';
    } else {
      double bytes = bytesPerSecond.toDouble();
      int unitIndex = 0;
      while (bytes >= _unitStep && unitIndex < _byteSpeedUnits.length - 1) {
        bytes /= _unitStep;
        unitIndex++;
      }
      return '${bytes.toStringAsFixed(decimals)} ${_byteSpeedUnits[unitIndex]}';
    }
  }

  /// Parses user-inputted [value] with [unit] back into byte count.
  static int parseToBytes(double value, String unit) {
    final normalized = unit.toUpperCase().trim();
    final multiplier = switch (normalized) {
      'B' => 1,
      'KB' => _unitStep,
      'MB' => _unitStep * _unitStep,
      'GB' => _unitStep * _unitStep * _unitStep,
      'TB' => _unitStep * _unitStep * _unitStep * _unitStep,
      _ => 1,
    };
    return (value * multiplier).round();
  }
}
