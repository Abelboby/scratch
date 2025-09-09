import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SerialPort? _portOne;
  SerialPortReader? _reader;
  List<String> _availablePorts = const [];
  String _lastLine = '';

  @override
  void initState() {
    super.initState();
    _initSerial();
  }

  void _initSerial() {
    // Close previous resources if any before re-initializing
    _reader?.close();
    _portOne?.close();
    _portOne?.dispose();
    _reader = null;
    _portOne = null;

    // List and print available ports
    final ports = SerialPort.availablePorts;
    _availablePorts = List<String>.from(ports);
    // Print to console as requested
    // ignore: avoid_print
    print(_availablePorts);

    if (_availablePorts.isEmpty) {
      return;
    }

    // Create serial port object: prefer COM4 if present, else first port
    final selectedPortName = _availablePorts.contains('COM4') ? 'COM4' : _availablePorts.first;
    _portOne = SerialPort(selectedPortName);

    // Open the port first
    final opened = _portOne!.openReadWrite();
    print('Opened: $opened  err=${SerialPort.lastError}  desc=${_portOne!.description}');
    if (!opened) {
      print('Failed to open port: $selectedPortName');
      _portOne!.dispose();
      _portOne = null;
      return;
    }
    // Apply configuration after opening
    final config = SerialPortConfig()
      ..baudRate = 9600
      ..bits = 8
      ..stopBits = 1
      ..parity = 0
      ..setFlowControl(SerialPortFlowControl.none);
    _portOne!.config = config;

    // Send a wake/request command once (adjust if your scale expects different)
    try {
      final wrote = _portOne!.write(Uint8List.fromList('R\r\n'.codeUnits));
      // ignore: avoid_print
      print('Wrote bytes: $wrote');
    } catch (e) {
      // ignore: avoid_print
      print('Write failed: $e');
    }
    // Do not call immediate synchronous read; rely on the reader stream
    // Set up reader and listen to data
    _reader = SerialPortReader(_portOne!);
    _reader!.stream.listen((Uint8List data) {
      final text = String.fromCharCodes(data);
      // ignore: avoid_print
      print(text);
      setState(() {
        _lastLine = text;
      });
    });
  }

  @override
  void dispose() {
    _reader?.close();
    _portOne?.close();
    _portOne?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Available ports: ${_availablePorts.join(', ')}'),
            const SizedBox(height: 12),
            Text(
                'Selected: ${_availablePorts.contains('COM4') ? 'COM4' : (_availablePorts.isNotEmpty ? _availablePorts.first : 'None')}'),
            const SizedBox(height: 12),
            Text('Last data: $_lastLine'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initSerial,
              child: const Text('Refresh Ports'),
            ),
          ],
        ),
      ),
      // Removed FAB; not needed for serial reading demo
      floatingActionButton: null,
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
