import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ModernDateRangePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?, TimeOfDay, TimeOfDay) onDateRangeSelected;

  const ModernDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeSelected,
  });

  @override
  State<ModernDateRangePicker> createState() => _ModernDateRangePickerState();
}

class _ModernDateRangePickerState extends State<ModernDateRangePicker> {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  DateTime _displayedMonth = DateTime.now();
  bool _isSelectingStart = true;
  
  // Time variables
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 0, minute: 0);

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _tempStartDate = widget.startDate;
    _tempEndDate = widget.endDate;
    if (_tempStartDate != null) {
      _displayedMonth = _tempStartDate!;
      _isSelectingStart = false;
    }
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('tr_TR', null);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_isSelectingStart || _tempStartDate == null) {
        _tempStartDate = date;
        _tempEndDate = null;
        _isSelectingStart = false;
      } else {
        if (date.isBefore(_tempStartDate!)) {
          _tempEndDate = _tempStartDate;
          _tempStartDate = date;
        } else {
          _tempEndDate = date;
        }
      }
    });
  }

  void _resetDates() {
    setState(() {
      _tempStartDate = null;
      _tempEndDate = null;
      _isSelectingStart = true;
      _startTime = const TimeOfDay(hour: 0, minute: 0);
      _endTime = const TimeOfDay(hour: 0, minute: 0);
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.red[600],
            colorScheme: ColorScheme.light(
              primary: Colors.red[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red[100]!),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              hourMinuteTextStyle: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              dialHandColor: Colors.red[600],
              dialBackgroundColor: Colors.red[50],
              dialTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.grey[800]!),
              hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.red[600]!
                      : Colors.red[50]!),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.grey[800]!),
              dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.red[600]!
                      : Colors.grey[200]!),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.grey[800]!),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[600],
              ),
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

  void _confirmSelection() {
    widget.onDateRangeSelected(_tempStartDate, _tempEndDate, _startTime, _endTime);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modern Header with Gradient
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[700]!, Colors.red[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.calendar_month, color: Colors.white, size: 20),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Tarih Aralığı Seç",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Date Display Cards
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDateDisplay(
                          "Başlangıç",
                          Icons.event_available,
                          _tempStartDate,
                          _isSelectingStart,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ),
                      Expanded(
                        child: _buildDateDisplay(
                          "Bitiş",
                          Icons.event_busy,
                          _tempEndDate,
                          !_isSelectingStart && _tempStartDate != null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Calendar Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Month Navigator
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: Colors.red[600], size: 28),
                          onPressed: _previousMonth,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                        Text(
                          DateFormat('MMMM yyyy', 'tr_TR').format(_displayedMonth),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: Colors.red[600], size: 28),
                          onPressed: _nextMonth,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Weekday Headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                        .map((day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 12),
                    // Calendar Grid
                    ..._buildCalendarGrid(),
                    SizedBox(height: 24),
                    
                    // Time Selection Section
                    Row(
                      children: [
                        // Start Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Başlangıç Saati',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectTime(context, true),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[200]!, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.access_time, color: Colors.red[600], size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        // End Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bitiş Saati',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectTime(context, false),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[200]!, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.access_time, color: Colors.red[600], size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetDates,
                          icon: Icon(Icons.refresh, size: 18),
                          label: Text("Temizle", style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[600],
                            side: BorderSide(color: Colors.red[200]!, width: 1.5),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _tempStartDate != null && _tempEndDate != null
                                ? LinearGradient(
                                    colors: [Colors.red[600]!, Colors.red[700]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _tempStartDate == null || _tempEndDate == null
                                ? Colors.grey[300]
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _tempStartDate != null && _tempEndDate != null
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _tempStartDate != null && _tempEndDate != null
                                  ? _confirmSelection
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Onayla",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDisplay(String label, IconData icon, DateTime? date, bool isActive) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.red[600] : Colors.white.withValues(alpha: 0.7),
              ),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.red[600] : Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            date != null ? DateFormat('dd MMM', 'tr_TR').format(date) : '-- ---',
            style: TextStyle(
              color: isActive ? Colors.red[700] : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> rows = [];
    List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(Expanded(child: SizedBox()));
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;
      final isStart = _tempStartDate != null &&
          date.year == _tempStartDate!.year &&
          date.month == _tempStartDate!.month &&
          date.day == _tempStartDate!.day;
      final isEnd = _tempEndDate != null &&
          date.year == _tempEndDate!.year &&
          date.month == _tempEndDate!.month &&
          date.day == _tempEndDate!.day;
      final isInRange = _tempStartDate != null &&
          _tempEndDate != null &&
          date.isAfter(_tempStartDate!) &&
          date.isBefore(_tempEndDate!);
      final isPast = date.isBefore(DateTime.now().subtract(Duration(days: 1)));

      dayWidgets.add(
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: isPast ? null : () => _selectDate(date),
              child: Container(
                margin: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: isStart || isEnd
                      ? LinearGradient(
                          colors: [Colors.red[600]!, Colors.red[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isInRange
                      ? Colors.red[50]
                      : isToday && !isStart && !isEnd
                          ? Colors.red[50]
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isStart && !isEnd
                      ? Border.all(color: Colors.red[300]!, width: 2)
                      : null,
                  boxShadow: isStart || isEnd
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isPast
                          ? Colors.grey[300]
                          : isStart || isEnd
                              ? Colors.white
                              : isInRange
                                  ? Colors.red[700]
                                  : isToday
                                      ? Colors.red[600]
                                      : Colors.grey[800],
                      fontWeight: isStart || isEnd
                          ? FontWeight.bold
                          : isToday
                              ? FontWeight.w600
                              : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if ((firstWeekday + day - 1) % 7 == 0 || day == daysInMonth) {
        rows.add(
          Row(children: List.from(dayWidgets)),
        );
        dayWidgets.clear();
      }
    }

    return rows;
  }
}

