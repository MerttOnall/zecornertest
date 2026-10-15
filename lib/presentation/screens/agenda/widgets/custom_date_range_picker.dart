import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const CustomDateRangePicker({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
  }) : super(key: key);

  @override
  _CustomDateRangePickerState createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    
    _focusedDay = widget.initialStartDate ?? DateTime.now();
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;
    _startTime = widget.initialStartDate != null 
        ? TimeOfDay.fromDateTime(widget.initialStartDate!) 
        : const TimeOfDay(hour: 0, minute: 0);
    _endTime = widget.initialEndDate != null 
        ? TimeOfDay.fromDateTime(widget.initialEndDate!) 
        : const TimeOfDay(hour: 0, minute: 0);
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
    });
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD9363E), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _onConfirm() {
    if (_rangeStart == null) {
      // Show an error or handle case where no date is selected
      return;
    }
    // If only start is selected, make end the same day.
    final end = _rangeEnd ?? _rangeStart;

    final startDate = DateTime(
      _rangeStart!.year,
      _rangeStart!.month,
      _rangeStart!.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDate = DateTime(
      end!.year,
      end.month,
      end.day,
      _endTime.hour,
      _endTime.minute,
    );
    
    if(endDate.isBefore(startDate)){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş tarihi başlangıç tarihinden önce olamaz!'))
      );
      return;
    }

    final result = DateTimeRange(start: startDate, end: endDate);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTableCalendar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                _buildTimePickers(),
                const SizedBox(height: 20),
                _buildConfirmButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCalendar() {
    return TableCalendar(
      locale: 'tr_TR',
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      rangeSelectionMode: RangeSelectionMode.toggledOn,
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      onRangeSelected: _onRangeSelected,
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black54),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black54),
      ),
      calendarStyle: CalendarStyle(
        rangeStartDecoration: const BoxDecoration(
          color: Color(0xFFD9363E),
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: const BoxDecoration(
          color: Color(0xFFD9363E),
          shape: BoxShape.circle,
        ),
        rangeHighlightColor: const Color(0xFFD9363E).withOpacity(0.2),
        todayDecoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Color(0xFFD9363E),
          shape: BoxShape.circle,
        ),
        weekendTextStyle: const TextStyle(color: Color(0xFFD9363E)),
      ),
       daysOfWeekStyle: const DaysOfWeekStyle(
        weekendStyle: TextStyle(color: Color(0xFFD9363E)),
      ),
    );
  }

  Widget _buildTimePickers() {
    final formatter = DateFormat('HH:mm');
    return Row(
      children: [
        Expanded(child: _buildTimePicker("Başlangıç Saati", _startTime, true)),
        const SizedBox(width: 16),
        Expanded(child: _buildTimePicker("Bitiş Saati", _endTime, false)),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                time.format(context),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check, size: 20, color: Colors.white),
        label: const Text('Seçimi Tamamla', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD9363E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
} 