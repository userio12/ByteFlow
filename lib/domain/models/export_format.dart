/// Supported data export formats for ByteFlow usage reports.
enum ExportFormat {
  json('JSON', 'json', 'application/json'),
  csv('CSV', 'csv', 'text/csv');

  final String label;
  final String extension;
  final String mimeType;

  const ExportFormat(this.label, this.extension, this.mimeType);
}
