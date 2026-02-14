import 'package:flutter/material.dart';
import '../../models/service_model.dart';
import '../../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  final ServiceModel service;

  const BookingScreen({super.key, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();

  DateTime? selectedDate;
  String? selectedTimeSlot;

  final List<String> timeSlots = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "01:00 PM",
    "02:00 PM",
    "03:00 PM",
    "04:00 PM",
    "05:00 PM",
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _bookService() async {
    if (selectedDate == null || selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date and time")),
      );
      return;
    }

    try {
      await _bookingService.createBooking(
        serviceId: widget.service.id,
        bookingDate: selectedDate!,
        timeSlot: selectedTimeSlot!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Booking successful!")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.service.name)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Price: LKR ${widget.service.price}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 10),

            Text(
              "Duration: ${widget.service.duration} mins",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _selectDate,
              child: Text(
                selectedDate == null
                    ? "Select Date"
                    : selectedDate.toString().split(' ')[0],
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedTimeSlot,
              hint: const Text("Select Time Slot"),
              items: timeSlots.map((slot) {
                return DropdownMenuItem(value: slot, child: Text(slot));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTimeSlot = value;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookService,
                child: const Text("Book Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
