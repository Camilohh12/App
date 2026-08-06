import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import 'login_screen.dart';

enum _LocationState { loading, serviceDisabled, denied, error, ready }

/// Pantalla que usa el sensor de GPS del dispositivo para mostrar la
/// ubicación actual de la terminal (útil para registrar desde dónde
/// se abrió la caja/el turno).
class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  _LocationState state = _LocationState.loading;
  Position? position;
  String? errorMessage;
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLocation());
  }

  Future<void> _fetchLocation() async {
    setState(() => state = _LocationState.loading);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() => state = _LocationState.serviceDisabled);
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => state = _LocationState.denied);
      return;
    }

    try {
      final result = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        position = result;
        lastUpdated = DateTime.now();
        state = _LocationState.ready;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No fue posible obtener la ubicación';
        state = _LocationState.error;
      });
    }
  }

  void _goToStart(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor de ubicación'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLocation,
        child: _buildBody(),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'sensors_fab_back',
            tooltip: 'Volver',
            onPressed: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            heroTag: 'sensors_fab_home',
            tooltip: 'Ir al inicio',
            onPressed: () => _goToStart(context),
            child: const Icon(Icons.home),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            heroTag: 'sensors_fab_logout',
            tooltip: 'Cerrar sesión',
            backgroundColor: AppColors.danger,
            onPressed: () => _logout(context),
            child: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (state) {
      case _LocationState.loading:
        return const Center(child: CircularProgressIndicator());

      case _LocationState.serviceDisabled:
        return _StatusMessage(
          icon: Icons.location_disabled,
          message:
          'El GPS del dispositivo está desactivado. Actívalo en '
              'los ajustes del sistema e intenta de nuevo.',
          onRetry: _fetchLocation,
        );

      case _LocationState.denied:
        return _StatusMessage(
          icon: Icons.location_off,
          message:
          'ComandaPOS necesita permiso de ubicación para mostrar '
              'dónde está la terminal. Habilítalo en los ajustes de '
              'la app.',
          onRetry: _fetchLocation,
        );

      case _LocationState.error:
        return _StatusMessage(
          icon: Icons.error_outline,
          message: errorMessage ?? 'Ocurrió un error inesperado',
          onRetry: _fetchLocation,
        );

      case _LocationState.ready:
        final pos = position!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'UBICACIÓN ACTUAL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${pos.latitude.toStringAsFixed(6)}, '
                        '${pos.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (lastUpdated != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Actualizado: '
                          '${lastUpdated!.hour.toString().padLeft(2, '0')}:'
                          '${lastUpdated!.minute.toString().padLeft(2, '0')}:'
                          '${lastUpdated!.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Precisión',
                    value: '±${pos.accuracy.toStringAsFixed(0)} m',
                    icon: Icons.gps_fixed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Altitud',
                    value: '${pos.altitude.toStringAsFixed(0)} m',
                    icon: Icons.terrain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Velocidad',
                    value: '${pos.speed.toStringAsFixed(1)} m/s',
                    icon: Icons.speed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Rumbo',
                    value: '${pos.heading.toStringAsFixed(0)}°',
                    icon: Icons.explore,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _fetchLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar ubicación'),
            ),
          ],
        );
    }
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  const _StatusMessage({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }
}
