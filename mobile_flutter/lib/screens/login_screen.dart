import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/table_provider.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import 'admin_shell_screen.dart';
import '../models/user.dart';
import 'bar_screen.dart';
import 'cashier_shell_screen.dart';
import 'kitchen_screen.dart';
import 'waiter_home_screen.dart';

enum _ConnectionStatus { checking, connected, disconnected }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  _ConnectionStatus connectionStatus = _ConnectionStatus.checking;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    _retryTimer?.cancel();

    if (mounted) {
      setState(() => connectionStatus = _ConnectionStatus.checking);
    }

    final isConnected = await context.read<ApiClient>().checkHealth();

    if (!mounted) return;

    setState(() {
      connectionStatus = isConnected
          ? _ConnectionStatus.connected
          : _ConnectionStatus.disconnected;
    });

    // Si el backend todavía no responde, reintenta solo cada 5s en
    // vez de dejar el estado "sin conexión" pegado hasta que se
    // reinicie la app.
    if (!isConnected) {
      _retryTimer = Timer(const Duration(seconds: 5), _checkConnection);
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      email: emailController.text,
      password: passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Correo o contraseña incorrectos',
          ),
        ),
      );
      return;
    }

    final user = authProvider.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Carga inicial de productos, mesas y órdenes antes de entrar.
    await Future.wait([
      context.read<ProductProvider>().refresh(),
      context.read<TableProvider>().refresh(),
      context.read<OrderProvider>().refresh(),
    ]);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    Widget destination;

    switch (user.role) {
      case UserRole.admin:
        destination = const AdminShellScreen();
        break;

      case UserRole.cashier:
        destination = const CashierShellScreen();
        break;

      case UserRole.kitchen:
        destination = const KitchenScreen();
        break;

      case UserRole.waiter:
        destination = const WaiterHomeScreen();
        break;

      case UserRole.bar:
        destination = const BarScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => destination,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.point_of_sale,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ComandaPOS Bar',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inicio de sesión de terminal',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isLoading ? null : login,
                    child: isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 28),
                  _ConnectionBadge(
                    status: connectionStatus,
                    onRetry: _checkConnection,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Usuarios de prueba',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'admin@comandapos.com / 1234\n'
                              'cajero@comandapos.com / 1234\n'
                              'cocina@comandapos.com / 1234',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final _ConnectionStatus status;
  final VoidCallback onRetry;

  const _ConnectionBadge({
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final String label;

    switch (status) {
      case _ConnectionStatus.checking:
        dotColor = AppColors.textSecondary;
        label = 'Verificando conexión con el servidor...';
        break;
      case _ConnectionStatus.connected:
        dotColor = AppColors.secondary;
        label = 'Conectado al servidor';
        break;
      case _ConnectionStatus.disconnected:
        dotColor = AppColors.danger;
        label = 'Sin conexión con el servidor';
        break;
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (status == _ConnectionStatus.disconnected) ...[
          const SizedBox(width: 6),
          const Icon(
            Icons.refresh,
            size: 14,
            color: AppColors.primary,
          ),
        ],
      ],
    );

    if (status != _ConnectionStatus.disconnected) {
      return content;
    }

    return InkWell(
      onTap: onRetry,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: content,
      ),
    );
  }
}
