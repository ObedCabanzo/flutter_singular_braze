import 'package:flutter/material.dart';
import 'package:singular_flutter_sdk/singular.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Registrar evento de vista
    Singular.eventWithArgs("Profile Screen Viewed", {"user_id": userId});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 30),
              Text(
                'User ID: $userId',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.email),
                        title: Text('Email'),
                        subtitle: Text('user@example.com'),
                      ),
                      ListTile(
                        leading: Icon(Icons.phone),
                        title: Text('Teléfono'),
                        subtitle: Text('+1 234 567 8900'),
                      ),
                      ListTile(
                        leading: Icon(Icons.location_on),
                        title: Text('Ubicación'),
                        subtitle: Text('Ciudad, País'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Singular.event("Profile Edit Clicked");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Editar perfil - Próximamente')),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Perfil'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}