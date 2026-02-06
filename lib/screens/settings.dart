import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const platform = MethodChannel('com.example.flutter_singular/notifications');
  bool _isLoading = false;
  bool? _permissionGranted;

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bool result = await platform.invokeMethod('requestNotificationPermission');
      
      setState(() {
        _permissionGranted = result;
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result 
              ? '✅ Permisos de notificación concedidos'
              : '❌ Permisos de notificación denegados',
          ),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    } on PlatformException catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notificaciones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Permite que la app te envíe notificaciones push para mantenerte informado.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Estado del permiso
            if (_permissionGranted != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _permissionGranted! 
                    ? Colors.green.shade50 
                    : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _permissionGranted! 
                      ? Colors.green 
                      : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _permissionGranted! 
                        ? Icons.check_circle 
                        : Icons.cancel,
                      color: _permissionGranted! 
                        ? Colors.green 
                        : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _permissionGranted!
                          ? 'Notificaciones activadas'
                          : 'Notificaciones desactivadas',
                        style: TextStyle(
                          color: _permissionGranted! 
                            ? Colors.green.shade900 
                            : Colors.red.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Botón para solicitar permiso
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _requestNotificationPermission,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.notifications_active),
                label: Text(
                  _isLoading 
                    ? 'Solicitando permiso...' 
                    : 'Activar Notificaciones',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}