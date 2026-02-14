import 'package:flutter/material.dart';
import '../../services/service_service.dart';
import '../../models/service_model.dart';
import 'booking_screen.dart';

//Appbar
class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Services"),
        centerTitle: true,
      ),

      body: customerHomeBody(),
    );
  }
}

//Customer Home Body
class customerHomeBody extends StatefulWidget {
  const customerHomeBody({super.key});

  @override
  State<customerHomeBody> createState() => _customerHomeBodyState();
}

class _customerHomeBodyState extends State<customerHomeBody> {
  final ServiceService _serviceService = ServiceService();
  bool _isLoading = true;
  List<ServiceModel> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final services = await _serviceService.fetchServices();
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading services: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_services.isEmpty) {
      return const Center(child: Text("No services available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(service.name),
            subtitle: Text("${service.duration} mins"),
            trailing: Text("Rs. ${service.price}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingScreen(service: service),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
