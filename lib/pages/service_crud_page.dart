import 'package:flutter/material.dart';

import '../models/service_item.dart';
import '../services/database_helper.dart';

class ServiceCrudPage extends StatefulWidget {
  const ServiceCrudPage({super.key});

  @override
  State<ServiceCrudPage> createState() => _ServiceCrudPageState();
}

class _ServiceCrudPageState extends State<ServiceCrudPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  List<ServiceItem> services = [];
  ServiceItem? editingService;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    final result = await DatabaseHelper.instance.getServices();

    setState(() {
      services = result;
    });
  }

  Future<void> saveService() async {
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();

    if (name.isEmpty || priceText.isEmpty) {
      showMessage('Please enter service name and price.');
      return;
    }

    final price = double.tryParse(priceText);

    if (price == null) {
      showMessage('Price must be a number.');
      return;
    }

    if (editingService == null) {
      await DatabaseHelper.instance.insertService(
        ServiceItem(
          name: name,
          price: price,
        ),
      );

      showMessage('Service added.');
    } else {
      await DatabaseHelper.instance.updateService(
        ServiceItem(
          id: editingService!.id,
          name: name,
          price: price,
        ),
      );

      showMessage('Service updated.');
    }

    clearForm();
    await loadServices();
  }

  Future<void> deleteService(int id) async {
    await DatabaseHelper.instance.deleteService(id);

    showMessage('Service deleted.');

    await loadServices();
  }

  void startEdit(ServiceItem service) {
    setState(() {
      editingService = service;
      nameController.text = service.name;
      priceController.text = service.price.toString();
    });
  }

  void clearForm() {
    setState(() {
      editingService = null;
      nameController.clear();
      priceController.clear();
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = editingService != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLite Service CRUD'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      isEditing ? 'Edit Service' : 'Add Service',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Service Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: saveService,
                            child: Text(isEditing ? 'Update' : 'Add'),
                          ),
                        ),
                        if (isEditing) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: clearForm,
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Service List',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: services.isEmpty
                  ? const Center(
                child: Text('No services found.'),
              )
                  : ListView.builder(
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];

                  return Card(
                    child: ListTile(
                      title: Text(service.name),
                      subtitle: Text('Rp${service.price.toStringAsFixed(0)}'),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            onPressed: () => startEdit(service),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {
                              deleteService(service.id!);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}