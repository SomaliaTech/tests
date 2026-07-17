// lib/features/admin/presentation/widgets/modern_calendar_picker.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class ModernCalendarPicker extends StatefulWidget {
  final Function(List<DateTime>) onDatesSelected;
  final List<DateTime> initialSelectedDates;

  const ModernCalendarPicker({
    super.key,
    required this.onDatesSelected,
    this.initialSelectedDates = const [],
  });

  @override
  State<ModernCalendarPicker> createState() => _ModernCalendarPickerState();
}

class _ModernCalendarPickerState extends State<ModernCalendarPicker> {
  late DateTime _focusedDay;
  late Set<DateTime> _selectedDays;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDays = widget.initialSelectedDates.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ), // Fixed deprecated withOpacity
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Dates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${_selectedDays.length} day${_selectedDays.length != 1 ? 's' : ''} selected',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (_selectedDays.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedDays.clear());
                      widget.onDatesSelected([]);
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: Color(0xFFE94560),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            // Fixed: Check if any selected day matches the current day
            selectedDayPredicate: (day) =>
                _selectedDays.any((selectedDay) => isSameDay(selectedDay, day)),
            eventLoader: (day) => _getEventsForDay(day),
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Color(0xFFE94560)),
              holidayTextStyle: const TextStyle(color: Color(0xFFE94560)),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(
                  0xFF6C63FF,
                ).withValues(alpha: 0.3), // Fixed deprecated withOpacity
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFF2ED573),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Color(0xFF6C63FF),
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xFF6C63FF),
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                // Fixed: Properly check and remove using isSameDay
                if (_selectedDays.any((d) => isSameDay(d, selectedDay))) {
                  _selectedDays.removeWhere((d) => isSameDay(d, selectedDay));
                } else {
                  _selectedDays.add(selectedDay);
                }
              });
              widget.onDatesSelected(_selectedDays.toList());
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),

          // Selected Dates Preview
          if (_selectedDays.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF6C63FF,
                ).withValues(alpha: 0.05), // Fixed deprecated withOpacity
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Period',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Fixed: Use Builder to isolate local variable and avoid cascade void return issues
                  Builder(
                    builder: (context) {
                      final sortedDates = _selectedDays.toList()
                        ..sort((a, b) => a.compareTo(b));
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sortedDates
                            .map<Widget>(
                              (date) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6C63FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('MMM d').format(date),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<String> _getEventsForDay(DateTime day) {
    return [];
  }
}
