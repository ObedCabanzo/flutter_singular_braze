import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:braze_plugin/braze_plugin.dart';
import 'package:singular_flutter_sdk/singular_link_params.dart';
import 'dart:io' show Platform;
import 'screens/settings.dart';
import 'screens/profile.dart';
import 'screens/products.dart';
import 'package:singular_flutter_sdk/singular.dart';
import 'package:singular_flutter_sdk/singular_config.dart';

String obtenerIdentificadorPorPlataforma() {
  if (Platform.isIOS) {
    return 'usuario_test_ios';
  } else if (Platform.isAndroid) {
    return 'usuario_test_android';
  } else {
    return 'usuario_test_desconocido';
  }
}

// GlobalKey para navegación desde deeplinks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  BrazePlugin braze = BrazePlugin();
  braze.changeUser(obtenerIdentificadorPorPlataforma());
  
  SingularConfig config = SingularConfig(
    'minders_6abd2f15',
    'cd99416ad34e47acc1a79d2e22fe3f93',
  );

  config.pushNotificationsLinkPaths = [
    ['/products', '/app/products'],
    ['/profile', '/app/profile'],
  ];
  config.espDomains = ['obed.lat', 'sng.link'];
  config.singularLinksHandler = (SingularLinkParams params) {
    String? deeplink = params.deeplink;
    String? passthrough = params.passthrough;
    bool? isDeferred = params.isDeferred;
    Map? urlParameters = params.urlParameters;

    print('Singular Deeplink Handler:');
    print('   Deeplink: $deeplink');
    print('   Passthrough: $passthrough');
    print('   Is Deferred: $isDeferred');  
    print('   URL Parameters: $urlParameters');

    if (deeplink != null) {
      _handleDeeplink(deeplink, urlParameters, source: 'singular');
    }
  };
  
  config.customUserId = obtenerIdentificadorPorPlataforma();
  print("Singular Configured with User ID: ${config.customUserId}");
  Singular.start(config);

  _setupDeepLinkChannel();

  runApp(const MyApp());
}

void _setupDeepLinkChannel() {
  const MethodChannel channel = 
      MethodChannel('com.example.flutter_singular/deeplinks');
  
  channel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'onDeepLink') {
      final data = Map<String, dynamic>.from(call.arguments);
      
      final url = data['url'] as String;
      final scheme = data['scheme'] as String;
      final host = data['host'] as String;
      final path = data['path'] as String;
      final queryParams = Map<String, String>.from(data['queryParams'] ?? {});
      
      print('Deep link received from native:');
      print('   URL: $url');
      print('   Scheme: $scheme');
      print('   Host: $host');
      print('   Path: $path');
      print('   Query params: $queryParams');
      
      _handleDeeplink(url, queryParams, source: 'native');
    }
  });
  
  print('Deep link channel initialized');
}

void _handleDeeplink(
  String deeplink, 
  Map? params, 
  {String source = 'unknown'}
) {
  print('Handling deeplink from $source: $deeplink');
  
  Future.delayed(const Duration(milliseconds: 500), () {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('ERROR: Navigator context not available');
      return;
    }

    Uri uri = Uri.parse(deeplink);
    String scheme = uri.scheme;
    String host = uri.host;
    String path = uri.path;
    
    // Combinar parámetros de la URL con los que vienen en params
    Map<String, dynamic> allParams = {
      ...uri.queryParameters,
      if (params != null) ...params,
    };

    print('Parsed deeplink:');
    print('   Scheme: $scheme');
    print('   Host: $host');
    print('   Path: $path');
    print('   All Params: $allParams');

    // Normalizar el path dependiendo del esquema
    String targetPath = '';
    
    if (scheme == 'https' || scheme == 'http') {
      // Universal link: https://flutter-singular.obed.lat/app/profile
      // Extraer el path después de /app/
      if (path.startsWith('/app/')) {
        targetPath = path.replaceFirst('/app/', '/');
      } else if (path.startsWith('/app')) {
        targetPath = path.replaceFirst('/app', '/');
      } else {
        targetPath = path;
      }
    } else {
      // Custom scheme: flutter-singular://app/profile
      // El host es "app" y el path es "/profile"
      if (host == 'app') {
        targetPath = path;
      } else {
        targetPath = '/$host$path';
      }
    }

    // Asegurar que el path empiece con /
    if (!targetPath.startsWith('/')) {
      targetPath = '/$targetPath';
    }

    print('Target path for navigation: $targetPath');

    // Ruta: /profile
    if (targetPath.contains('/profile')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userId: allParams['user_id']?.toString() ?? 
                    allParams['userId']?.toString() ?? 
                    'default',
          ),
        ),
      );
      Singular.eventWithArgs("Deeplink Profile Opened", {
        "source": source,
        "user_id": allParams['user_id']?.toString() ?? 'default',
      });
      return;
    }

    // Ruta: /products
    if (targetPath.contains('/products')) {
      String? productId = allParams['product_id']?.toString() ?? 
                         allParams['productId']?.toString();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductsScreen(productId: productId),
        ),
      );
      Singular.eventWithArgs("Deeplink Products Opened", {
        "source": source,
        "product_id": productId ?? 'none',
      });
      return;
    }

    // Ruta: /settings
    if (targetPath.contains('/settings')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
      Singular.eventWithArgs("Deeplink Settings Opened", {
        "source": source,
      });
      return;
    }

    // Si no coincide con ninguna ruta conocida
    print('WARNING: Unhandled deeplink path: $targetPath');
    Singular.eventWithArgs("Deeplink Unhandled", {
      "source": source,
      "path": targetPath,
      "original_url": deeplink,
    });
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CounterTab(),
    const ProfileTab(),
    const ProductsTab(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    Singular.eventWithArgs("Tab Changed", {"tab_index": index});
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Counter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
        ],
      ),
    );
  }
}

// Tab 1: Counter
class CounterTab extends StatefulWidget {
  const CounterTab({super.key});

  @override
  State<CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<CounterTab> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    Singular.eventWithArgs("Counter Incremented", {"new_count": _counter});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('You have pushed the button this many times:'),
          Text(
            '$_counter',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// Tab 2: Profile
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Profile Tab',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(userId: 'tab_user'),
                ),
              );
              Singular.event("Profile Button Clicked");
            },
            child: const Text('Ver Perfil Completo'),
          ),
        ],
      ),
    );
  }
}

// Tab 3: Products
class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag, size: 100, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            'Products Tab',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductsScreen(productId: '123'),
                ),
              );
              Singular.event("Products Button Clicked");
            },
            child: const Text('Ver Productos'),
          ),
        ],
      ),
    );
  }
}