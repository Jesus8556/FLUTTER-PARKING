import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Parking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FlutterLogo(size: 200),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  List<Company> companies = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response =
          await http.get(Uri.parse('http://54.196.243.240:9000/api/empresa'));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          companies =
              responseData.map((json) => Company.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Parking App'),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: fetchData,
        child: companies.isNotEmpty
            ? ListView.builder(
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  return CompanyCard(
                      company: companies[index],
                      onTap: () => showNiveles(context, companies[index].id));
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  Future<void> showNiveles(BuildContext context, String empresaId) async {
    final nivelesResponse = await http
        .get(Uri.parse('http://54.196.243.240:9000/api/nivel?empresaId=$empresaId'));
    if (nivelesResponse.statusCode == 200) {
      final List<dynamic> nivelesData = json.decode(nivelesResponse.body);
      List<Nivel> niveles =
          nivelesData.map((json) => Nivel.fromJson(json)).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NivelesPage(
                  niveles: niveles,
                  onUpdate: fetchData,
                )),
      );
    } else {
      print('Failed to load niveles');
    }
  }
}

class NivelesPage extends StatelessWidget {
  final List<Nivel> niveles;
  final VoidCallback onUpdate;

  NivelesPage({required this.niveles, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Niveles de la empresa'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          onUpdate();
          await Future.delayed(Duration(seconds: 2));
        },
        child: ListView.builder(
          itemCount: niveles.length,
          itemBuilder: (context, index) {
            return NivelCard(nivel: niveles[index]);
          },
        ),
      ),
    );
  }
}

class Company {
  final String id;
  final String nombre;
  final String email;
  final int telefono;
  final String imagen;

  Company({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.imagen,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      telefono: json['telefono'] ?? 0,
      imagen: json['imagen'] ?? '',
    );
  }
}

class Nivel {
  final String id;
  final String nivel;
  final String imagen;
  final Company empresa;

  Nivel({
    required this.id,
    required this.nivel,
    required this.imagen,
    required this.empresa,
  });

  factory Nivel.fromJson(Map<String, dynamic> json) {
    return Nivel(
      id: json['_id'] ?? '',
      nivel: json['nivel'] ?? '',
      imagen: json['imagen'] ?? '',
      empresa: Company.fromJson(json['empresa'] ?? {}),
    );
  }
}

class CompanyCard extends StatelessWidget {
  final Company company;
  final VoidCallback onTap;

  CompanyCard({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(10),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            CachedNetworkImage(
              imageUrl: 'http://54.196.243.240:9000/${company.imagen}',
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) {
                print('Error loading image: $error');
                return CachedNetworkImage(
                  imageUrl:
                      'https://circontrol.com/wp-content/uploads/2023/10/180125-Circontrol-BAIXA-80-1.jpg',
                  width: 100,
                  height: 100,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                );
              },
            ),
            ListTile(
              title: Text(company.nombre),
              subtitle: Text(company.email),
              trailing: Text('Teléfono: ${company.telefono}'),
            ),
          ],
        ),
      ),
    );
  }
}

class NivelCard extends StatelessWidget {
  final Nivel nivel;

  NivelCard({required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: nivel.imagen,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) {
              print('Error loading image: $error');
              return CachedNetworkImage(
                imageUrl:
                    'https://circontrol.com/wp-content/uploads/2023/10/180125-Circontrol-BAIXA-80-1.jpg',
                width: 100,
                height: 100,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              );
            },
          ),
          ListTile(
            title: Text(nivel.nivel),
            subtitle: Text('Empresa: ${nivel.empresa.nombre}'),
            trailing: ElevatedButton(
              onPressed: () => showParking(context, nivel.id),
              child: Text('Mostrar Parking'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showParking(BuildContext context, String nivelId) async {
    final parkingResponse = await http.get(
        Uri.parse('http://54.196.243.240:9000/api/parking?nivelId=$nivelId'));
    if (parkingResponse.statusCode == 200) {
      final List<dynamic> parkingData = json.decode(parkingResponse.body);
      List<Parking> parkingList =
          parkingData.map((json) => Parking.fromJson(json)).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParkingPage(
            parkingList: parkingList,
            onUpdate: onUpdate,
          ),
        ),
      );
    } else {
      print('Failed to load parking');
    }
  }

  Future<void> onUpdate() async {
    // Puedes agregar aquí cualquier lógica necesaria al actualizar
    print('Actualizado');
  }
}

class ParkingPage extends StatelessWidget {
  final List<Parking> parkingList;
  final VoidCallback onUpdate;

  ParkingPage({required this.parkingList, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lugares de estacionamiento'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          onUpdate();
          await Future.delayed(Duration(seconds: 2));
        },
        child: ListView.builder(
          itemCount: parkingList.length,
          itemBuilder: (context, index) {
            return ParkingCard(parking: parkingList[index]);
          },
        ),
      ),
    );
  }
}

class Parking {
  final String id;
  final String lugar;
  final Nivel nivel;
  final bool estado;

  Parking({
    required this.id,
    required this.lugar,
    required this.nivel,
    required this.estado,
  });

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['_id'] ?? '',
      lugar: json['lugar'] ?? '',
      nivel: Nivel.fromJson(json['nivel'] ?? {}),
      estado: json['estado'] ?? false,
    );
  }
}

class ParkingCard extends StatelessWidget {
  final Parking parking;

  ParkingCard({required this.parking});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          ListTile(
            title: Text('Lugar: ${parking.lugar}'),
            subtitle: Text('Estado: ${parking.estado ? 'Ocupado' : 'Libre'}'),
          ),
        ],
      ),
    );
  }
}
