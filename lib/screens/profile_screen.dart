import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'register_screen.dart';
import 'package:flutter_app/core/themes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _profileImagePath;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (_isLoggedIn) {
        _nameController.text = prefs.getString('name') ?? '';
        _emailController.text = prefs.getString('email') ?? '';
        _phoneController.text = prefs.getString('phone') ?? '';
        _cityController.text = prefs.getString('city') ?? '';
        _countryController.text = prefs.getString('country') ?? '';
        _profileImagePath = prefs.getString('profileImagePath');
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final registeredEmail = prefs.getString('email');
      final registeredPassword = prefs.getString('password');
      if (_emailController.text == registeredEmail &&
          _passwordController.text == registeredPassword) {
        await prefs.setBool('isLoggedIn', true);
        setState(() {
          _isLoggedIn = true;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Giriş başarılı!',
                style: TextStyle(color: AppColors.textDark),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'E-posta veya şifre hatalı!',
                style: TextStyle(color: AppColors.textDark),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    setState(() {
      _isLoggedIn = false;
      _emailController.clear();
      _passwordController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Çıkış yapıldı.',
            style: TextStyle(color: AppColors.textDark),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
  try {
    // Request permission
    final permissionStatus = await Permission.photos.request();
    if (permissionStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fotoğraf erişim izni reddedildi.',
              style: TextStyle(color: AppColors.textDark),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    if (permissionStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fotoğraf erişim izni kalıcı olarak reddedildi. Lütfen ayarlara gidip izni verin.',
              style: TextStyle(color: AppColors.textDark),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hiçbir fotoğraf seçilmedi.',
              style: TextStyle(color: AppColors.textDark),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    final file = File(pickedFile.path);
    if (await file.exists()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', pickedFile.path);
      setState(() {
        _profileImagePath = pickedFile.path;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil fotoğrafı başarıyla güncellendi!',
              style: TextStyle(color: AppColors.textDark),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else {
      throw Exception('Seçilen dosya mevcut değil.');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fotoğraf seçilirken bir hata oluştu: $e',
            style: TextStyle(color: AppColors.textDark),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _nameController.text);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('phone', _phoneController.text);
      await prefs.setString('city', _cityController.text);
      await prefs.setString('country', _countryController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil güncellendi!',
              style: TextStyle(color: AppColors.textDark),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    ).then((_) => _checkLoginStatus());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        actions: _isLoggedIn
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _handleLogout,
                ),
              ]
            : null,
      ),
      body: _isLoggedIn ? _buildProfileView() : _buildLoginView(),
    );
  }

  Widget _buildLoginView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş Geldiniz',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Lütfen giriş yapın veya yeni bir hesap oluşturun.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-posta alanı boş olamaz';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Geçerli bir e-posta adresi girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre alanı boş olamaz';
                        }
                        if (value.length < 6) {
                          return 'Şifre en az 6 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Giriş Yap'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: _navigateToRegister,
              child: const Text('Hesabınız yok mu? Kayıt Ol'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Şifre sıfırlama bağlantısı e-postanıza gönderildi.',
                      style: TextStyle(color: AppColors.textDark),
                    ),
                    backgroundColor: AppColors.accent,
                  ),
                );
              },
              child: const Text('Şifremi Unuttum'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Kullanıcı Profili',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.surface,
              backgroundImage: _profileImagePath != null
                  ? FileImage(File(_profileImagePath!))
                  : null,
              child: _profileImagePath == null
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.textSecondary,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _pickImage,
            child: const Text('Profil Fotoğrafını Değiştir'),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ad soyad alanı boş olamaz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-posta alanı boş olamaz';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Geçerli bir e-posta adresi girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon Numarası (İsteğe Bağlı)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Şehir (İsteğe Bağlı)',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Ülke (İsteğe Bağlı)',
                        prefixIcon: Icon(Icons.public_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Bilgileri Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}