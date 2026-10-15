import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/infrastructure/task/task_repository.dart';
import 'package:zecorner/models/task/task_model.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({Key? key}) : super(key: key);

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  String selectedSort = 'En Yeni';
  String selectedCategory = 'Hepsi';
  String search = '';

  final List<String> sortOptions = ['En Yeni', 'En Eski', 'A-Z', 'Z-A'];

  /// Web (ZeOnline) görev tipi filtresi: Hepsi + bilinen tipler + listedeki diğer API tipleri
  static const List<String> _baseCategoryLabels = [
    'Hepsi',
    'Kullanıcı Görevleri',
    'Beni Ara',
    'Toplantı',
  ];

  String _typeCategoryLabelFromType(String type) {
    switch (type) {
      case 'USER_TASK':
        return 'Kullanıcı Görevleri';
      case 'CALL_CUSTOMER':
        return 'Beni Ara';
      case 'MEETING':
        return 'Toplantı';
      default:
        return type.isEmpty ? 'Diğer' : type;
    }
  }

  String? _typeCodeForCategoryLabel(String label) {
    if (label == 'Hepsi') return null;
    switch (label) {
      case 'Kullanıcı Görevleri':
        return 'USER_TASK';
      case 'Beni Ara':
        return 'CALL_CUSTOMER';
      case 'Toplantı':
        return 'MEETING';
      default:
        for (final t in _tasks) {
          if (_typeCategoryLabelFromType(t.type) == label) return t.type;
        }
        return label;
    }
  }

  List<String> _categoryPickerItems() {
    final extra = <String>{};
    for (final t in _tasks) {
      final label = _typeCategoryLabelFromType(t.type);
      if (!_baseCategoryLabels.contains(label)) extra.add(label);
    }
    final sortedExtra = extra.toList()..sort();
    return [..._baseCategoryLabels, ...sortedExtra];
  }

  /// Web `/api/get-tasks/?sort=desc|asc` — başlık sıralaması istemcide
  String? _apiSortQuery() {
    switch (selectedSort) {
      case 'En Yeni':
        return 'desc';
      case 'En Eski':
        return 'asc';
      default:
        return null;
    }
  }

  // API state
  final TaskRepository _taskRepository = TaskRepository();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final typeParam = _typeCodeForCategoryLabel(selectedCategory);
      final result = await _taskRepository.getTasks(
        page: 0,
        pageSize: 100,
        sort: _apiSortQuery(),
        type: typeParam,
      );

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          print('❌ Task yükleme hatası: ${failure.message}');
        },
        (taskResponse) {
          setState(() {
            _tasks = taskResponse.tasks;
            _isLoading = false;
          });
          print('✅ ${_tasks.length} task yüklendi');
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Görevler yüklenirken bir hata oluştu: $e';
      });
      print('❌ Task yükleme exception: $e');
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Devam Ediyor':
      case 'IN_PROGRESS':
        return const Color(0xFFFB8C00); // Turuncu
      case 'Atandı':
      case 'ASSIGNED':
        return const Color(0xFF1976D2); // Mavi
      case 'Tamamlandı':
      case 'COMPLETED':
        return const Color(0xFF43A047); // Yeşil
      case 'İptal Edildi':
      case 'CANCELLED':
        return const Color(0xFFE53935); // Kırmızı
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${DateFormat('dd/MM/yyyy').format(date)} -';
  }

  String _formatTime(DateTime date) {
    return '${DateFormat('HH:mm').format(date)} -';
  }

  Future<void> _openTaskDetail(Task task) async {
    final result = await Navigator.pushNamed(
      context,
      '/task-detail',
      arguments: task,
    );
    if (!mounted) {
      return;
    }
    if (result is Task) {
      setState(() {
        final i = _tasks.indexWhere((t) => t.id == result.id);
        if (i != -1) {
          _tasks[i] = result;
        }
      });
    }
  }

  void _showTaskOptionsMenu(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFE53935)),
              title: const Text('Düzenle',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.pushNamed(
                  context,
                  '/edit-task-manager',
                  arguments: task,
                );
                if (!context.mounted) return;
                if (result is Task) {
                  setState(() {
                    final i = _tasks.indexWhere((t) => t.id == result.id);
                    if (i != -1) {
                      _tasks[i] = result;
                    }
                  });
                }
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, task);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Sil'),
        content: Text('${task.title} görevini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: API'den silme işlemi yapılacak
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Görev silindi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changeTaskState(Task task, String newStateDesc) {
    final code = Task.pickerLabelToApiState(newStateDesc);
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(state: code);
      }
    });
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Görev durumu "$newStateDesc" olarak güncellendi'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _fold(String value) {
    return value
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  bool _matchesSearch(Task task, String query) {
    if (query.isEmpty) return true;
    final folded = _fold(query);
    final haystack = _fold([
      task.title,
      task.typeDescription,
      task.stateDescription,
      task.priorityDescription,
      ...task.relatedContacts.map((contact) => contact.title),
    ].join(' '));
    return haystack.contains(folded);
  }

  List<Task> _getFilteredAndSortedTasks() {
    final query = search.trim();
    var filtered = _tasks.where((task) {
      final typeLabel = _typeCategoryLabelFromType(task.type);
      final matchesCategory = selectedCategory == 'Hepsi' ||
          typeLabel == selectedCategory ||
          task.type == selectedCategory;
      return matchesCategory && _matchesSearch(task, query);
    }).toList();

    // Sort
    switch (selectedSort) {
      case 'En Yeni':
        filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case 'En Eski':
        filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case 'A-Z':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Z-A':
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredAndSortedTasks();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      // Role sistemine göre sidebar seçimi
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'Görev Yöneticisi');
        },
      ),
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
      },
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
      appBar: AdminPanelAppBar(
        title: "Görevler",
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: GestureDetector(
        onTap: () {
          if (_isDrawerOpen) {
            _scaffoldKey.currentState?.closeDrawer();
          }
        },
        child: AbsorbPointer(
          absorbing: _isDrawerOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Web ile aynı mantık: aranabilir sıralama + görev tipi (kategori)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: _SearchableBottomSheetList(
                                title: 'Sıralama',
                                items: sortOptions,
                                selected: selectedSort,
                                showSearchBar: false,
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() => selectedSort = result);
                            await _loadTasks();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Sıralama: $selectedSort',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800])),
                              const SizedBox(width: 6),
                              Icon(Icons.keyboard_arrow_down,
                                  size: 18, color: Colors.grey[500]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final items = _categoryPickerItems();
                          if (!items.contains(selectedCategory)) {
                            setState(() => selectedCategory = 'Hepsi');
                          }
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: _SearchableBottomSheetList(
                                title: 'Görev tipi',
                                items: items,
                                selected: selectedCategory,
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() => selectedCategory = result);
                            await _loadTasks();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(selectedCategory,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800])),
                              const SizedBox(width: 6),
                              Icon(Icons.keyboard_arrow_down,
                                  size: 18, color: Colors.grey[500]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search and Add Button Section
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => search = v),
                          decoration: InputDecoration(
                            hintText: 'Görev Ara...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Add Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/add-task-manager');
                          },
                          icon: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                          label: const Text(
                            'Yeni Görev',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Kartlar
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48, color: Colors.red[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _loadTasks,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Tekrar Dene'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE53935),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : filteredTasks.isEmpty
                              ? Center(
                                  child: Text('Görev bulunmadı',
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 16)))
                              : RefreshIndicator(
                                  onRefresh: _loadTasks,
                                  child: ListView.separated(
                                    itemCount: filteredTasks.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 18),
                                    itemBuilder: (context, i) {
                                      final task = filteredTasks[i];
                                      final participants = task.relatedContacts;
                                      return Card(
                                        elevation: 6,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18)),
                                        margin: EdgeInsets.zero,
                                        color: Colors.white,
                                        shadowColor:
                                            Colors.black.withOpacity(0.08),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              18, 18, 18, 18),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Üst kısım: Durum dropdown + Üç nokta menü
                                              Row(
                                                children: [
                                                  // Durum Dropdown
                                                  Expanded(
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                12),
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey.shade300,
                                                            width: 1),
                                                      ),
                                                      child: DropdownButtonHideUnderline(
                                                        child: DropdownButton<String>(
                                                          value: task.pickerStatusLabel,
                                                          isExpanded: true,
                                                          icon: Icon(
                                                              Icons.keyboard_arrow_down,
                                                              size: 18,
                                                              color: Colors.grey[600]),
                                                          style: TextStyle(
                                                            color: getStatusColor(
                                                                task.pickerStatusLabel),
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 14,
                                                          ),
                                                          items: Task.cardPickerStatuses
                                                              .map((String state) {
                                                            return DropdownMenuItem<String>(
                                                              value: state,
                                                              child: Row(
                                                                children: [
                                                                  Icon(Icons.circle,
                                                                      size: 10,
                                                                      color: getStatusColor(state)),
                                                                  const SizedBox(width: 8),
                                                                  Text(state),
                                                                ],
                                                              ),
                                                            );
                                                          }).toList(),
                                                          onChanged: (String? newValue) {
                                                            if (newValue != null) {
                                                              _changeTaskState(task, newValue);
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Üç nokta menü
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.more_vert,
                                                      color: Color(0xFFE53935),
                                                    ),
                                                    onPressed: () {
                                                      _showTaskOptionsMenu(context, task);
                                                    },
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  onTap: () =>
                                                      _openTaskDetail(task),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 2),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          task.title,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 18,
                                                              color: Color(
                                                                  0xFF23263B)),
                                                        ),
                                                        const SizedBox(
                                                            height: 20),
                                                        const Text(
                                                          "Görev Başlangıç Tarihi",
                                                          style: TextStyle(
                                                              fontSize: 15,
                                                              color: Color(
                                                                  0xFF23263B),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .calendar_today,
                                                                size: 16,
                                                                color: Colors
                                                                    .grey[500]),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              _formatDate(task
                                                                  .startTime),
                                                              style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Color(
                                                                      0xFF23263B)),
                                                            ),
                                                            const SizedBox(
                                                                width: 16),
                                                            Icon(
                                                                Icons
                                                                    .access_time,
                                                                size: 16,
                                                                color: Colors
                                                                    .grey[500]),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              _formatTime(task
                                                                  .startTime),
                                                              style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Color(
                                                                      0xFF23263B)),
                                                            ),
                                                          ],
                                                        ),
                                                        if (task.endTime !=
                                                            null) ...[
                                                          const SizedBox(
                                                              height: 20),
                                                          const Text(
                                                            "Görev Bitiş Tarihi",
                                                            style: TextStyle(
                                                                fontSize: 15,
                                                                color: Color(
                                                                    0xFF23263B),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          ),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                  Icons
                                                                      .calendar_today,
                                                                  size: 16,
                                                                  color: Colors
                                                                          .grey[
                                                                      500]),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                _formatDate(task
                                                                    .endTime!),
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                        0xFF23263B)),
                                                              ),
                                                              const SizedBox(
                                                                  width: 16),
                                                              Icon(
                                                                  Icons
                                                                      .access_time,
                                                                  size: 16,
                                                                  color: Colors
                                                                          .grey[
                                                                      500]),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                _formatTime(task
                                                                    .endTime!),
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                        0xFF23263B)),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        const SizedBox(
                                                            height: 14),
                                                        if (participants
                                                            .isNotEmpty)
                                                          SizedBox(
                                                            height: 34,
                                                            child: Stack(
                                                              children: [
                                                                for (int j = 0;
                                                                    j <
                                                                        participants
                                                                            .length;
                                                                    j++)
                                                                  Positioned(
                                                                    left: j *
                                                                        22.0,
                                                                    child:
                                                                        Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              Colors.white,
                                                                          width:
                                                                              2,
                                                                        ),
                                                                        shape: BoxShape
                                                                            .circle,
                                                                      ),
                                                                      child:
                                                                          CircleAvatar(
                                                                        radius:
                                                                            16,
                                                                        backgroundColor:
                                                                            Colors.grey[300],
                                                                        child:
                                                                            Text(
                                                                          participants[j].title.isNotEmpty
                                                                              ? participants[j].title[0].toUpperCase()
                                                                              : '?',
                                                                          style:
                                                                              const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
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
                print('Task Manager Screen - Bottom Navbar - User Role Codes: $userRoleCodes');
                
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
}

/// Seçim alt sayfası: isteğe bağlı arama, dengeli tipografi ve seçim vurgusu
class _SearchableBottomSheetList extends StatefulWidget {
  final String title;
  final List<String> items;
  final String selected;
  final bool showSearchBar;

  const _SearchableBottomSheetList({
    required this.title,
    required this.items,
    required this.selected,
    this.showSearchBar = true,
  });

  @override
  State<_SearchableBottomSheetList> createState() =>
      _SearchableBottomSheetListState();
}

class _SearchableBottomSheetListState extends State<_SearchableBottomSheetList> {
  late final TextEditingController _searchController;
  String _query = '';

  static const Color _ink = Color(0xFF1A1D2E);
  static const Color _accent = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    return widget.items
        .where((raw) => raw.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxListHeight = media.size.height * 0.55;

    Widget listSection() {
      if (_filtered.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Text(
            'Sonuç bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
          ),
        );
      }

      final list = ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final raw = _filtered[i];
          final isSelected = widget.selected == raw;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(raw),
              borderRadius: BorderRadius.circular(12),
              splashColor: _accent.withOpacity(0.08),
              highlightColor: _accent.withOpacity(0.06),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFF5F5)
                      : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _accent.withOpacity(0.35)
                        : const Color(0xFFE8EAED),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        raw,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: _ink,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _accent,
                        size: 22,
                      )
                    else
                      const SizedBox(width: 22, height: 22),
                  ],
                ),
              ),
            ),
          );
        },
      );

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxListHeight),
        child: list,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B7280),
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.close_rounded, size: 22),
              ),
            ],
          ),
        ),
        if (widget.showSearchBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 15,
                color: _ink,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Ara...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade500,
                  size: 22,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
              ),
            ),
          ),
        listSection(),
        SizedBox(height: media.padding.bottom > 0 ? 4 : 8),
      ],
    );
  }
}
