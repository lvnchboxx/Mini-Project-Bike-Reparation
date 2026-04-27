import 'package:flutter/material.dart';

class RepairRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String requestId;
  final bool showAdminButtons;
  final void Function(String status)? onStatusChanged;

  const RepairRequestCard({
    super.key,
    required this.data,
    required this.requestId,
    required this.showAdminButtons,
    this.onStatusChanged,
  });

  Color getStatusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'on_queue':
        return Colors.blue;
      case 'in_repair':
        return Colors.purple;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String formatStatus(String status) {
    switch (status) {
      case 'waiting':
        return 'Waiting';
      case 'on_queue':
        return 'On Queue';
      case 'in_repair':
        return 'In Repair';
      case 'done':
        return 'Done';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'waiting';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['serviceType'] ?? 'Unknown Service',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text('Customer: ${data['customerEmail'] ?? '-'}'),
            Text('Description: ${data['description'] ?? '-'}'),
            Text(
              'Estimated Price: Rp${data['estimatedPrice'] == null ? '-' : (data['estimatedPrice'] as num).toStringAsFixed(0)}',
            ),
            Text('Latitude: ${data['latitude'] ?? '-'}'),
            Text('Longitude: ${data['longitude'] ?? '-'}'),
            const SizedBox(height: 8),
            Chip(
              label: Text(formatStatus(status)),
              backgroundColor: getStatusColor(status).withOpacity(0.2),
            ),
            if (showAdminButtons) ...[
              const Divider(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => onStatusChanged?.call('on_queue'),
                    child: const Text('Set On Queue'),
                  ),
                  OutlinedButton(
                    onPressed: () => onStatusChanged?.call('in_repair'),
                    child: const Text('Set In Repair'),
                  ),
                  FilledButton(
                    onPressed: () => onStatusChanged?.call('done'),
                    child: const Text('Mark Done'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}