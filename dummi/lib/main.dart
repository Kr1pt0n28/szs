import 'package:dummi/views/app/app_view.dart';
import 'package:dummi/views/sesion/tts_view.dart';
import 'package:flutter/material.dart';
import 'package:sura_voxia/sura_voxia.dart';
import 'views/modelo/prueba.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VoxiaConfig.initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dummi App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Shared voice controller — lives here so state persists across tabs
  final VoxiaController _voiceController = VoxiaController.defaultInstance();

  int _currentIndex = 0;
  int _previousIndex = 0;

  // Voice session tab index
  static const int _voiceTabIndex = 2;

  @override
  void dispose() {
    _voiceController.dispose();
    super.dispose();
  }

  Future<void> _onTabTap(int index) async {
    // Auto-logout when leaving the voice session tab
    if (_previousIndex == _voiceTabIndex && index != _voiceTabIndex) {
      final state = _voiceController.state;
      if (state.status != SessionStatus.loggedOut) {
        await _voiceController.logout();
      }
    }
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all tabs alive — state is preserved when switching
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AppView(controller: _voiceController),
          const ModelsTestView(),
          TtsView(controller: _voiceController),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0033a0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onTabTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'App'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calculate), label: 'Modelo'),
          BottomNavigationBarItem(
              icon: Icon(Icons.mic), label: 'Sesión Voz'),
        ],
      ),
    );
  }
}
