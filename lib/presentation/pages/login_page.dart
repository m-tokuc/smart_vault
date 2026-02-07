import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../core/auth/auth_service.dart';
import '../../injection_container.dart';
import '../widgets/glassmorphic_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = sl<AuthService>();
  bool _isAuthenticating = false;
  String _authStatus = '';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheck = await _authService.isBiometricAvailable();
    if (canCheck) {
      _authenticate();
    } else {
      setState(() {
        _authStatus = 'Biometrics not available on this device.';
      });
      // For now, if no biometrics, we might just let them in or show error.
      // In a real app, we'd have password fallback.
      // For demo, we'll add a "Skip" button if biometrics fail/unavailable.
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _authStatus = 'Authenticating...';
    });

    try {
      bool authenticated = await _authService.authenticate();
      if (authenticated) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        setState(() {
          _authStatus = 'Authentication failed. Tap to retry.';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _authStatus = 'Error: ${e.message}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F1221), Color(0xFF1E233C)],
              ),
            ),
          ),

          // Ambient Glow
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Logo / Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFFa29bfe)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_outlined,
                        size: 50, color: Colors.white),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'SmartVault',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Secure Your Future',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),

                  const Spacer(),

                  // Auth Status
                  if (_authStatus.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        _authStatus,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.redAccent.withOpacity(0.8)),
                      ),
                    ),

                  // Login Button
                  GestureDetector(
                    onTap: _isAuthenticating ? null : _authenticate,
                    child: GlassmorphicContainer(
                      height: 60,
                      width: double.infinity,
                      borderRadius: 16,
                      blur: 10,
                      border: 1,
                      color: Colors.white.withOpacity(0.1),
                      child: Center(
                        child: _isAuthenticating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text(
                                'Login with Biometrics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Fallback / Skip (For Demo purposes mostly, or dev env)
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    child: Text(
                      'Enter PIN (Simulated)',
                      style: TextStyle(color: Colors.white.withOpacity(0.4)),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
