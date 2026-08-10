import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  UserRole selectedRole = UserRole.cashier;
  bool obscurePassword = true;
  bool isSubmitting = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String roleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.cashier:
        return 'Cajero';
      case UserRole.kitchen:
        return 'Cocina';
      case UserRole.waiter:
        return 'Mesero';
      case UserRole.bar:
        return 'Barra';
    }
  }

  Future<void> createUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final errorMessage = await context.read<AuthProvider>().registerUser(
      name: name,
      email: email,
      password: password,
      role: selectedRole,
    );

    if (!mounted) return;

    setState(() => isSubmitting = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Usuario "$name" creado como ${roleText(selectedRole)}',
        ),
      ),
    );

    nameController.clear();
    emailController.clear();
    passwordController.clear();
    setState(() => selectedRole = UserRole.cashier);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear usuario'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
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
                  setState(() => obscurePassword = !obscurePassword);
                },
                icon: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<UserRole>(
            initialValue: selectedRole,
            decoration: const InputDecoration(
              labelText: 'Rol',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: UserRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(roleText(role)),
              );
            }).toList(),
            onChanged: (role) {
              if (role == null) return;
              setState(() => selectedRole = role);
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: isSubmitting ? null : createUser,
            icon: isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.person_add),
            label: const Text('Crear usuario'),
          ),
        ],
      ),
    );
  }
}
