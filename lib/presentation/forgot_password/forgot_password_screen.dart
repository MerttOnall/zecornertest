import 'package:flutter/material.dart';
import 'package:zecorner/presentation/register/register_screen.dart';
import 'package:zecorner/widgets/custom_text_field.dart';
import 'package:flutter_svg/flutter_svg.dart'; // flutter_svg import edilmiştir

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(238, 238, 238, 1),
              Color.fromRGBO(224, 224, 224, 1),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Geometrik desen arka plan
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 
                         MediaQuery.of(context).size.height),
              painter: BackgroundPainter(),
            ),
            // SVG'nin kartın dışında üst kısımda yer almasını sağlıyoruz
            Positioned(
              top: 95, // SVG'nin üst kısmını belirliyoruz
              left: MediaQuery.of(context).size.width / 4, // Yatayda ortalıyoruz
              child: SvgPicture.asset(
                'assets/logo/zecorner-logo1.svg', // SVG dosyanızın yolu
                height: 45, // Yükseklik ayarı
                width: 45,  // Genişlik ayarı
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    color: Color.fromRGBO(255, 255, 255, 1),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Şifremi Unuttum',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Şifrenizi sıfırlamak için e-posta adresinizi giriniz.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'E-Posta Adresiniz',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _emailController,
                            hintText: 'E-posta adresinizi giriniz',
                          ),
                            
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // Şifre sıfırlama e-postası gönderme işlemi
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Şifremi Sıfırla',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                            
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Giriş sayfasına dön',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
