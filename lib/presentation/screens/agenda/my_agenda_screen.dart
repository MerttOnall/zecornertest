import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:zecorner/core/cubit/task_cubit.dart';
import 'package:zecorner/core/cubit/task_state.dart';
import 'package:zecorner/core/cubit/note_cubit.dart';
import 'package:zecorner/core/cubit/note_state.dart';
import 'package:zecorner/models/task/task_model.dart';
import 'package:zecorner/models/note/note_model.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/screens/agenda/widgets/create_task_dialog.dart';
import 'package:zecorner/presentation/screens/agenda/widgets/create_note_dialog.dart';
import 'package:zecorner/presentation/screens/agenda/widgets/task_detail_dialog.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';

class MyAgendaScreen extends StatefulWidget {
  const MyAgendaScreen({super.key});

  @override
  State<MyAgendaScreen> createState() => _MyAgendaScreenState();
}

enum AgendaView { calendar, tasks, notes }

class _MyAgendaScreenState extends State<MyAgendaScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AgendaView _selectedView = AgendaView.calendar;
  bool _isDrawerOpen = false;
  static bool _drawerOpenedOnce = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _localeInitialized = false;
  String _noteSearchQuery = '';

  // Placeholder data for notes
  final List<Map<String, dynamic>> _notes = [
    {
      'title': 'deneme',
      'date': '16/04/2025 - 00:00',
      'content': 'Bu, ilk notun içeriğidir.'
    },
    {
      'title': 'Toplantı Notları',
      'date': '15/04/2025 - 11:30',
      'content': '- Proje A sunumu yapıldı.\n- Bütçe konuları görüşüldü.'
    },
  ];

  Map<String, dynamic>? _selectedNote;

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!_drawerOpenedOnce) {
    //     _scaffoldKey.currentState?.openDrawer();
    //     _drawerOpenedOnce = true;
    //   }
    // });
    _selectedDay = _focusedDay;
    _initializeLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskCubit>().fetchTasks();
      context.read<NoteCubit>().fetchNotes();
    });
  }

  void _initializeLocale() async {
    await initializeDateFormatting('tr_TR', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return Scaffold(
        key: _scaffoldKey,
        // Role sistemine göre sidebar seçimi
        drawer: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
            return RoleSidebar(currentPage: 'Akıllı Ajandam');
          },
        ),
        appBar: AdminPanelAppBar(
          title: 'Akıllı Ajandam',
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      // Role sistemine göre sidebar seçimi
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final authCubit = context.read<AuthCubit>();
            return FutureBuilder<List<String>>(
              future: authCubit.getUserRoleCodes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Drawer(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final userRoleCodes = snapshot.data ?? [];
                print('My Agenda Screen - Sidebar - User Role Codes: $userRoleCodes');
                
                // Web sitesindeki mantığa göre sidebar seçimi
                return RoleSidebar(currentPage: 'Akıllı Ajandam');
              },
            );
          }
          return RoleSidebar(currentPage: 'Akıllı Ajandam');
        },
      ),
      backgroundColor: Colors.white,
      appBar: AdminPanelAppBar(
        title: 'Akıllı Ajandam',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildToggleButton(AgendaView.calendar, 'Takvim Görünümü')),
                  Expanded(child: _buildToggleButton(AgendaView.tasks, 'Görev Tablosu')),
                  Expanded(child: _buildToggleButton(AgendaView.notes, 'Not Defterim')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildSelectedView(),
            ),
          ],
        ),
      ),
      // Role sistemine göre navbar seçimi
      bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final authCubit = context.read<AuthCubit>();
            return FutureBuilder<List<String>>(
              future: authCubit.getUserRoleCodes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final userRoleCodes = snapshot.data ?? [];
                print('My Agenda Screen - Bottom Navbar - User Role Codes: $userRoleCodes');
                
                // Web sitesindeki mantığa göre navbar seçimi
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_office_broker') || userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_form_applications') || userRoleCodes.contains('role_form_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_sale_applications') || userRoleCodes.contains('role_sale_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else {
                  return const FrancahiseNavbar(currentIndex: 0);
                }
              },
            );
          }
          return const AdminNavbar(currentIndex: 0);
        },
      ),
    );
  }

  Widget _buildToggleButton(AgendaView view, String text) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = view;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD9363E) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case AgendaView.calendar:
        return _buildCalendarView();
      case AgendaView.tasks:
        return _buildTaskBoardView();
      case AgendaView.notes:
        return _buildNotesView();
      default:
        return _buildCalendarView();
    }
  }

  Widget _buildTaskBoardView() {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Task> upcomingTasks = [];
        List<Task> ongoingTasks = [];
        List<Task> completedTasks = [];

        if (state is TaskLoaded) {
          upcomingTasks = state.tasks.where((t) => t.state == 'ASSIGNED').toList();
          ongoingTasks = state.tasks.where((t) => t.state == 'IN_PROGRESS').toList();
          completedTasks = state.tasks.where((t) => t.state == 'COMPLETED').toList();
        } else if (state is TaskError) {
          return Center(child: Text('Hata: ${state.message}'));
        }

        return Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const CreateTaskDialog();
                    },
                  ).then((_) {
                    context.read<TaskCubit>().fetchTasks();
                  });
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Yeni Görev Oluştur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9363E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTaskColumn('Yaklaşan Görevler', upcomingTasks),
                  _buildTaskColumn('Devam Eden Görevler', ongoingTasks),
                  _buildTaskColumn('Tamamlanan Görevler', completedTasks),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskColumn(String title, List<Task> tasks) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.85,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(tasks[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    String? dateRange;
    if (task.endTime != null) {
      dateRange = '${DateFormat('dd/MM/yyyy', 'tr_TR').format(task.startTime)} - ${DateFormat('dd/MM/yyyy', 'tr_TR').format(task.endTime!)}';
    } else {
      dateRange = DateFormat('dd/MM/yyyy', 'tr_TR').format(task.startTime);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                Icon(Icons.more_horiz, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text("Görev Zamanı", style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22.0),
              child: Text(dateRange, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ),
            const SizedBox(height: 16),
            if (task.relatedContacts.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 28,
                  child: Stack(
                    children: [
                      for (int i = 0; i < task.relatedContacts.length && i < 3; i++)
                        Positioned(
                          left: i * 18.0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: (task.relatedContacts[i].picture != null && task.relatedContacts[i].picture!.startsWith('http'))
                                ? NetworkImage(task.relatedContacts[i].picture!)
                                : null,
                            child: (task.relatedContacts[i].picture == null || !task.relatedContacts[i].picture!.startsWith('http'))
                                ? Text(
                                    task.relatedContacts[i].title.isNotEmpty ? task.relatedContacts[i].title[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (state is TaskError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Görevler yüklenirken hata oluştu:\n${state.message}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        List<Task> tasks = [];
        if (state is TaskLoaded) {
          tasks = state.tasks;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              return _buildWideCalendarLayout(tasks);
            } else {
              return _buildMobileCalendarLayout(tasks);
            }
          },
        );
      },
    );
  }

  Widget _buildWideCalendarLayout(List<Task> tasks) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Akış
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Akış',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _buildEventsList(tasks, isWide: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Right side: Calendar
        Expanded(
          flex: 7,
          child: _buildTableCalendar(tasks),
        ),
      ],
    );
  }

  Widget _buildMobileCalendarLayout(List<Task> tasks) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableCalendar(tasks),
          const SizedBox(height: 24.0),
          const Text(
            'Akış',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12.0),
          _buildEventsList(tasks, isWide: false),
        ],
      ),
    );
  }

  List<Task> _getTasksForDay(DateTime day, List<Task> tasks) {
    return tasks.where((task) {
      final start = task.startTime.toLocal();
      final end = task.endTime?.toLocal();
      final due = task.due?.toLocal();
      
      bool isMatch = isSameDay(start, day);
      if (end != null) {
        final dayStart = DateTime(day.year, day.month, day.day);
        final taskStart = DateTime(start.year, start.month, start.day);
        final taskEnd = DateTime(end.year, end.month, end.day);
        if ((dayStart.isAtSameMomentAs(taskStart) || dayStart.isAfter(taskStart)) && 
            (dayStart.isAtSameMomentAs(taskEnd) || dayStart.isBefore(taskEnd))) {
          isMatch = true;
        }
      }
      if (due != null && isSameDay(due, day)) {
        isMatch = true;
      }
      return isMatch;
    }).toList();
  }

  Widget _buildTableCalendar(List<Task> tasks) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<Task>(
        locale: 'tr_TR',
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => _getTasksForDay(day, tasks),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black54),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black54),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFFD9363E).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFFD9363E),
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: Colors.red[800]),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return const SizedBox();
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: events.take(3).map((event) {
                final Task task = event as Task;
                Color markerColor;
                if (task.state == 'COMPLETED') {
                  markerColor = Colors.green;
                } else if (task.state == 'IN_PROGRESS') {
                  markerColor = Colors.orange;
                } else {
                  markerColor = Colors.blue;
                }
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 6.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: markerColor,
                  ),
                );
              }).toList(),
            );
          },
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekendStyle: TextStyle(color: Colors.red[800]),
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Task> allTasks, {bool isWide = false}) {
    // Web'deki gibi tüm task'ları gösteriyoruz, tarihe göre listeliyoruz.
    final List<Task> events = List.from(allTasks);

    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: isWide ? null : BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text('Görev bulunmamaktadır.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      decoration: isWide ? null : BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
         boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: isWide ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final date = event.startTime.toLocal();
          final title = event.title;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMMM', 'tr_TR').format(date), 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title, 
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, color: Color(0xFFD9363E), size: 22),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => TaskDetailDialog(task: event),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFFD9363E), size: 22),
                      onPressed: () {
                        // TODO: Edit task
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFD9363E), size: 22),
                      onPressed: () {
                        // TODO: Delete task
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[200]),
      ),
    );
  }

  Widget _buildNotesView() {
    return BlocBuilder<NoteCubit, NoteState>(
      builder: (context, state) {
        if (state is NoteLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (state is NoteError) {
          // Eğer 404 hatasıysa listeyi boş gösterelim (Backend'de hiç not yoksa 404 dönüyor olabilir)
          if (state.message.contains('404')) {
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final newNote = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => const CreateNoteDialog(),
                      );
                      if (newNote != null) {
                        context.read<NoteCubit>().fetchNotes();
                      }
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Yeni Not Oluştur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9363E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 700) {
                        return _buildWideNotesLayout([]);
                      } else {
                        return _buildMobileNotesLayout([]);
                      }
                    },
                  ),
                ),
              ],
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Notlar yüklenirken hata oluştu:\n${state.message}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        List<Note> notes = [];
        if (state is NoteLoaded) {
          notes = state.notes;
        }

        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final newNote = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const CreateNoteDialog(),
                  );
                  if (newNote != null) {
                    context.read<NoteCubit>().fetchNotes();
                  }
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Yeni Not Oluştur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9363E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 700) {
                    return _buildWideNotesLayout(notes);
                  } else {
                    return _buildMobileNotesLayout(notes);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWideNotesLayout(List<Note> notes) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildNotesListPane(notes),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 3,
          child: _buildNoteDetailPane(),
        ),
      ],
    );
  }

  Widget _buildMobileNotesLayout(List<Note> notes) {
    if (_selectedNote != null) {
      return _buildMobileNoteDetail();
    } else {
      return _buildNotesListPane(notes);
    }
  }

  Widget _buildMobileNoteDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextButton.icon(
            onPressed: () => setState(() => _selectedNote = null),
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text('Tüm Notlar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        Expanded(child: _buildNoteDetailPane()),
      ],
    );
  }

  Future<void> _editNote(Map<String, dynamic> note) async {
    final editedNote = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateNoteDialog(
        initialTitle: note['title'],
        initialContent: note['content'],
        initialDate: note['date'],
        initialCustomer: note['customer'],
        initialListing: note['listing'],
        isEdit: true,
      ),
    );
    if (editedNote != null) {
      context.read<NoteCubit>().fetchNotes();
      setState(() {
        _selectedNote = editedNote;
      });
    }
  }

  Widget _buildNotesListPane(List<Note> notes) {
    final filteredNotes = notes.where((note) {
      final query = _noteSearchQuery.toLowerCase();
      return note.title.toLowerCase().contains(query)
        || note.content.toLowerCase().contains(query)
        || (note.customerTitle?.toLowerCase() ?? '').contains(query)
        || (note.listingTitle?.toLowerCase() ?? '').contains(query);
    }).toList();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notlarım', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          _buildNotesSearchBar(),
          const SizedBox(height: 8),
          Expanded(
            child: filteredNotes.isEmpty 
              ? Center(
                  child: Text(
                    'Henüz not eklenmemiş.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                )
              : ListView.separated(
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = filteredNotes[index];
                  
                  // Note'u map formatına çevir, böylece eski tasarımla uyumlu çalışmaya devam etsin.
                  final noteMap = {
                    'id': note.id,
                    'title': note.title,
                    'content': note.content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''), // Strip HTML tags simple way
                    'date': note.startDate != null ? DateFormat('dd/MM/yyyy - HH:mm').format(note.startDate!.toLocal()) : DateFormat('dd/MM/yyyy - HH:mm').format(note.createdAt.toLocal()),
                    'customer': note.customerTitle,
                    'listing': note.listingTitle,
                  };
                  
                  final isSelected = _selectedNote?['id'] == note.id;
                  
                  return Material(
                    color: isSelected ? const Color(0xFFD9363E).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedNote = noteMap),
                      onLongPress: () => _editNote(noteMap),
                      borderRadius: BorderRadius.circular(8.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    noteMap['date'] as String,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.edit, color: const Color(0xFFD9363E), size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
              ),
          )
        ],
      ),
    );
  }

  Widget _buildNotesSearchBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _noteSearchQuery = value),
        decoration: InputDecoration(
          hintText: 'Not Ara',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          suffixIcon: const Icon(Icons.search, color: Color(0xFFD9363E)),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
        ),
      ),
    );
  }

  Widget _buildNoteDetailPane() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: _selectedNote == null
          ? const Center(
              child: Text(
              'Lütfen görüntülemek istediğiniz notu seçin',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedNote!['title'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedNote!['date'],
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const Divider(height: 32),
                  Text(
                    _selectedNote!['content'],
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  if (_selectedNote!['customer'] != null && _selectedNote!['customer'].toString().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('İlgili Müşteri:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_selectedNote!['customer'], style: const TextStyle(fontSize: 15)),
                  ],
                  if (_selectedNote!['listing'] != null && _selectedNote!['listing'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('İlgili İlan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_selectedNote!['listing'], style: const TextStyle(fontSize: 15)),
                  ],
                ],
              ),
            ),
    );
  }
}
