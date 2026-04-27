import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../widgets/repair_request_card.dart';
import 'login_page.dart';
import 'service_crud_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Future<void> updateStatus(
      BuildContext context,
      String requestId,
      String status,
      ) async {
    await FirebaseFirestore.instance
        .collection('repair_requests')
        .doc(requestId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'done') {
      await NotificationService.showRepairDoneNotification();
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to $status'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Repair Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Manage Services',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServiceCrudPage(),
                ),
              );
            },
            icon: const Icon(Icons.build),
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Logged in as admin'),
              subtitle: Text(user.email ?? ''),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('repair_requests')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No repair requests yet.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final requestId = docs[index].id;

                    return RepairRequestCard(
                      data: data,
                      requestId: requestId,
                      showAdminButtons: true,
                      onStatusChanged: (status) {
                        updateStatus(context, requestId, status);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}