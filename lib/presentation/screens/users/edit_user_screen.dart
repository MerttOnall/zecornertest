import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/presentation/screens/users/edit_user_args.dart';
import 'package:zecorner/core/cubit/form_controller_cubit.dart';
import 'package:zecorner/core/enums/action_enum.dart';
import 'package:zecorner/models/forms/user_edit_form_model.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  EditUserArgs? _user;
  bool _isExpanded = false;
  bool _isLoadingRoles = false;
  final ContactApiRepository _contactRepository = ContactApiRepository();
  late FormControllerCubit<UserEditFormModel, bool> _formControllerCubit;
  late UserEditFormModel _formModel;

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  List<String> _availableRoles = [];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _formControllerCubit = FormControllerCubit<UserEditFormModel, bool>();
    _formModel = UserEditFormModel.empty();
    _loadAvailableRoles();
  }

  Future<void> _loadAvailableRoles() async {
    setState(() {
      _isLoadingRoles = true;
    });

    try {
      final result = await _contactRepository.getAvailableRoles();
      result.fold(
        (failure) {
          // Hata durumunda varsayılan roller
          setState(() {
            _availableRoles = [
              "Ofis Broker",
              "Admin",
              "Satış Başvuru Form İşlemleri",
              "Haber İşlemleri",
              "Sıkça Sorulan Sorular İşlemleri",
              "Blog İşlemleri",
              "Kampanya İşlemleri",
              "İlan Onaylama",
              "Gayrimenkul Danışmanı",
              "Ofis Asistanı",
              "Takım Lideri",
            ];
          });
        },
        (roles) {
          setState(() {
            _availableRoles = roles;
          });
        },
      );
    } catch (e) {
      // Hata durumunda varsayılan roller
      setState(() {
        _availableRoles = [
          "Ofis Broker",
          "Admin",
          "Satış Başvuru Form İşlemleri",
          "Haber İşlemleri",
          "Sıkça Sorulan Sorular İşlemleri",
          "Blog İşlemleri",
          "Kampanya İşlemleri",
          "İlan Onaylama",
          "Gayrimenkul Danışmanı",
          "Ofis Asistanı",
          "Takım Lideri",
        ];
      });
    } finally {
      setState(() {
        _isLoadingRoles = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_user == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is EditUserArgs) {
        _user = args;
      }
      if (_user != null) {
        _firstNameController.text = _user!.firstName;
        _lastNameController.text = _user!.lastName;
        _emailController.text = _user!.email;
        _phoneController.text = _user!.phone;

        // Form model'i güncelle
        _formModel = UserEditFormModel.fromUser(
          firstName: _user!.firstName,
          lastName: _user!.lastName,
          email: _user!.email,
          phone: _user!.phone,
          roles: [_user!.role],
          isActive: _user!.isActive,
        );

        // Form controller'ı update action'ına set et
        _formControllerCubit.setAction(ACTION.update);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _formControllerCubit.close();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (_user == null) return;

    // Validation
    if (_formModel.selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir rol seçin'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE53935),
        ),
      ),
    );

    try {
      // Önce durumu güncelle
      final statusResult = await _contactRepository.updateContactStatus(
        contactId: int.parse(_user!.userNumber),
        isActive: _formModel.isActive,
      );

      if (statusResult.isLeft()) {
        // Durum güncelleme başarısız
        if (mounted) {
          Navigator.pop(context);
          final failure = statusResult.fold((l) => l, (r) => null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure?.message ?? 'Durum güncelleme başarısız'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Sonra rolleri güncelle
      final rolesResult = await _contactRepository.updateContactRoles(
        contactId: int.parse(_user!.userNumber),
        roles: _formModel.selectedRoles,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        if (rolesResult.isRight()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı bilgileri başarıyla güncellendi!'),
              backgroundColor: Colors.green,
            ),
          );

          // Liste ekranı `pop(true)` ile yenileme yapıyor; sonuç verilmezse mobilde liste eski kalıyor.
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        } else {
          final failure = rolesResult.fold((l) => l, (r) => null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure?.message ?? 'Rol güncelleme başarısız'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme sırasında hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _formControllerCubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AdminPanelInAppBar(
          title: "Kullanıcı Düzenle",
          onBackPressed: () => Navigator.pop(context),
        ),
        body: BlocConsumer<FormControllerCubit<UserEditFormModel, bool>,
            FormControllerState<bool>>(
          listener: (context, state) {
            if (state.status == FormStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kullanıcı rolleri başarıyla güncellendi'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
            } else if (state.status == FormStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: ${state.errorMessage}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return GestureDetector(
              onTap: () {
                if (_isExpanded) {
                  setState(() {
                    _isExpanded = false;
                  });
                }
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Durum Switch
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Durum",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Switch.adaptive(
                              value: _formModel.isActive,
                              onChanged: (value) {
                                setState(() {
                                  _formModel =
                                      _formModel.copyWith(isActive: value);
                                });
                              },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Kişisel Bilgiler
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Kişisel Bilgiler",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _firstNameController,
                              enabled: false, // Sadece okunabilir
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromRGBO(238, 46, 36, 1),
                                    width: 2,
                                  ),
                                ),
                                labelText: "Ad",
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[
                                    200], // Daha koyu gri, değiştirilemez olduğunu göster
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              enabled: false, // Sadece okunabilir
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromRGBO(238, 46, 36, 1),
                                    width: 2,
                                  ),
                                ),
                                labelText: "Soyad",
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[
                                    200], // Daha koyu gri, değiştirilemez olduğunu göster
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      // İletişim Bilgileri
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "İletişim Bilgileri",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              enabled: false, // Sadece okunabilir
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromRGBO(238, 46, 36, 1),
                                    width: 2,
                                  ),
                                ),
                                labelText: "E-posta",
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[
                                    200], // Daha koyu gri, değiştirilemez olduğunu göster
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              enabled: false, // Sadece okunabilir
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color.fromRGBO(238, 46, 36, 1),
                                    width: 2,
                                  ),
                                ),
                                labelText: "Telefon",
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[
                                    200], // Daha koyu gri, değiştirilemez olduğunu göster
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Kişi Yetkileri
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Kişi Yetkileri",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                // Dropdown içine tıklandığında kapanmasını engelle
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isExpanded = !_isExpanded;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            if (_formModel
                                                .selectedRoles.isEmpty)
                                              const Text("Seçiniz",
                                                  style: TextStyle(
                                                      color: Colors.grey)),
                                            if (_formModel
                                                .selectedRoles.isNotEmpty)
                                              Expanded(
                                                child: SizedBox(
                                                  height: 40,
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount: _formModel
                                                        .selectedRoles.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final role = _formModel
                                                          .selectedRoles[index];
                                                      return Container(
                                                        margin: const EdgeInsets
                                                            .only(right: 8),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFFFFEBEE),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              role,
                                                              style:
                                                                  const TextStyle(
                                                                color: Color(
                                                                    0xFFE53935),
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _formModel =
                                                                      _formModel
                                                                          .copyWith(
                                                                    selectedRoles: _formModel
                                                                        .selectedRoles
                                                                        .where((r) =>
                                                                            r !=
                                                                            role)
                                                                        .toList(),
                                                                  );
                                                                });
                                                              },
                                                              child: const Icon(
                                                                Icons.close,
                                                                size: 18,
                                                                color: Color(
                                                                    0xFFE53935),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            Icon(
                                              _isExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: Colors.grey[600],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_isExpanded)
                                      _isLoadingRoles
                                          ? const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: _availableRoles.length,
                                              itemBuilder: (context, index) {
                                                final role =
                                                    _availableRoles[index];
                                                final isSelected = _formModel
                                                    .selectedRoles
                                                    .contains(role);
                                                return InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      if (isSelected) {
                                                        _formModel =
                                                            _formModel.copyWith(
                                                          selectedRoles:
                                                              _formModel
                                                                  .selectedRoles
                                                                  .where((r) =>
                                                                      r != role)
                                                                  .toList(),
                                                        );
                                                      } else {
                                                        _formModel =
                                                            _formModel.copyWith(
                                                          selectedRoles: [
                                                            ..._formModel
                                                                .selectedRoles,
                                                            role
                                                          ],
                                                        );
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(
                                                            color: Colors
                                                                .grey[300]!),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          role,
                                                          style: TextStyle(
                                                            color: isSelected
                                                                ? const Color(
                                                                    0xFFE53935)
                                                                : Colors.black,
                                                            fontWeight:
                                                                isSelected
                                                                    ? FontWeight
                                                                        .w500
                                                                    : FontWeight
                                                                        .normal,
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          const Icon(
                                                            Icons.check,
                                                            color: Color(
                                                                0xFFE53935),
                                                            size: 20,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Güncelle Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _updateUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Bilgileri Güncelle",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
