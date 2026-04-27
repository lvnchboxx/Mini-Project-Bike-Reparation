import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/service_item.dart';
import '../services/database_helper.dart';

class AddRepairRequestPage extends StatefulWidget {
  const AddRepairRequestPage({super.key});

  @override
  State<AddRepairRequestPage> createState() => _AddRepairRequestPageState();
}

class _AddRepairRequestPageState extends State<AddRepairRequestPage> {
  final descriptionController = TextEditingController();

  List<ServiceItem> services = [];
  ServiceItem? selectedService;

  double? latitude;
  double? longitude;

  bool loadingServices = true;
  bool submitting = false;
  bool gettingLocation = false;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    final result = await DatabaseHelper.instance.getServices();

    setState(() {
      services = result;
      if (services.isNotEmpty) {
        selectedService = services.first;
      }
      loadingServices = false;
    });
  }

  Future<void> getCurrentLocation() async {
    setState(() {
      gettingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        showMessage('Please enable location service on your phone.');
        setState(() {
          gettingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showMessage('Location permission denied.');
        setState(() {
          gettingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      showMessage('Location added.');
    } catch (e) {
      showMessage('Location error: $e');
    }

    if (mounted) {
      setState(() {
        gettingLocation = false;
      });
    }
  }

  Future<void> submitRequest() async {
    if (selectedService == null) {
      showMessage('Please select a service.');
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      showMessage('Please enter a description.');
      return;
    }

    if (latitude == null || longitude == null) {
      showMessage('Please tap Use GPS first.');
      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('repair_requests').add({
        'customerId': user.uid,
        'customerEmail': user.email,
        'serviceType': selectedService!.name,
        'estimatedPrice': selectedService!.price,
        'description': descriptionController.text.trim(),
        'status': 'waiting',
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Repair request submitted.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      showMessage('Submit error: $e');
    }

    if (mounted) {
      setState(() {
        submitting = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingServices) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Repair Request'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<ServiceItem>(
              value: selectedService,
              decoration: const InputDecoration(
                labelText: 'Repair Service',
                border: OutlineInputBorder(),
              ),
              items: services.map((service) {
                return DropdownMenuItem(
                  value: service,
                  child: Text('${service.name} - Rp${service.price.toStringAsFixed(0)}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedService = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Problem Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Bike Location'),
                subtitle: latitude == null
                    ? const Text('No location added')
                    : Text('Lat: $latitude\nLng: $longitude'),
                trailing: FilledButton(
                  onPressed: gettingLocation ? null : getCurrentLocation,
                  child: gettingLocation
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(),
                  )
                      : const Text('Use GPS'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submitting ? null : submitRequest,
                child: submitting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(),
                )
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}