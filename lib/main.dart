import 'package:flutter/material.dart';

void main() {
  runApp(const CamperSolarApp());
}

class CamperSolarApp extends StatelessWidget {
  const CamperSolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camper Solar Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
        ),
      ),
      home: const CamperHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Aparato {
  String nombre;
  double potenciaWh; // Consumo en vatios-hora o W
  double horasUso;
  bool usaInversor;

  Aparato({
    required this.nombre,
    required this.potenciaWh,
    required this.horasUso,
    required this.usaInversor,
  });

  double get consumoTotalDiario => potenciaWh * horasUso;
}

class CamperHomePage extends StatefulWidget {
  const CamperHomePage({super.key});

  @override
  State<CamperHomePage> createState() => _CamperHomePageState();
}

class _CamperHomePageState extends State<CamperHomePage> {
  // Configuración de la batería y sistema
  final TextEditingController capacidadBateriaCtrl = TextEditingController(text: '150');
  final TextEditingController potenciaSolarCtrl = TextEditingController(text: '350');
  final TextEditingController boosterCtrl = TextEditingController(text: '30');

  // Controladores para añadir aparatos
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController potenciaCtrl = TextEditingController();
  final TextEditingController horasCtrl = TextEditingController();
  bool usaInversor = false;

  final List<Aparato> aparatos = [
    Aparato(nombre: 'Nevera de compresor', potenciaWh: 45, horasUso: 24, usaInversor: false),
    Aparato(nombre: 'Luces LED', potenciaWh: 15, horasUso: 5, usaInversor: false),
    Aparato(nombre: 'Bomba de agua', potenciaWh: 40, horasUso: 0.5, usaInversor: false),
  ];

  final List> preajustes = [
    {
      'nombre': 'Nevera de compresor',
      'potencia': 45.0,
      'horas': 24.0,
      'inv': false,
      'icon': Icons.ac_unit,
    },
    {
      'nombre': 'Calefacción estacionaria',
      'potencia': 40.0,
      'horas': 8.0,
      'inv': false,
      'icon': Icons.local_fire_department,
    },
    {
      'nombre': 'Luces LED',
      'potencia': 15.0,
      'horas': 5.0,
      'inv': false,
      'icon': Icons.lightbulb,
    },
    {
      'nombre': 'Ordenador / Portátil',
      'potencia': 65.0,
      'horas': 3.0,
      'inv': true,
      'icon': Icons.laptop,
    },
    {
      'nombre': 'Cafetera 220V',
      'potencia': 1250.0,
      'horas': 0.2,
      'inv': true,
      'icon': Icons.coffee,
    },
  ];

  void _agregarAparato() {
    if (nombreCtrl.text.isEmpty || potenciaCtrl.text.isEmpty || horasCtrl.text.isEmpty) return;
    setState(() {
      aparatos.add(Aparato(
        nombre: nombreCtrl.text,
        potenciaWh: double.tryParse(potenciaCtrl.text) ?? 0.0,
        horasUso: double.tryParse(horasCtrl.text) ?? 0.0,
        usaInversor: usaInversor,
      ));
      nombreCtrl.clear();
      potenciaCtrl.clear();
      horasCtrl.clear();
      usaInversor = false;
    });
  }

  void _eliminarAparato(int index) {
    setState(() {
      aparatos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    double capacidadBateria = double.tryParse(capacidadBateriaCtrl.text) ?? 150.0;
    double potenciaSolar = double.tryParse(potenciaSolarCtrl.text) ?? 350.0;
    double potenciaBooster = double.tryParse(boosterCtrl.text) ?? 30.0;

    // Cálculos energéticos
    double consumoTotalWhDia = aparatos.fold(0.0, (sum, item) => sum + item.consumoTotalDiario);
    double energiaUtilBateria = (capacidadBateria * 12) * 0.8; // Asumiendo 12V y 80% DOD seguras (ej. Lítio/AGM)
    double diasAutonomia = consumoTotalWhDia > 0 ? energiaUtilBateria / consumoTotalWhDia : 0;
    
    // Estimación solar aproximada (4 horas de sol pico equivalentes)
    double generacionSolarDia = potenciaSolar * 4.0;
    double balanceEnergetico = generacionSolarDia - consumoTotalWhDia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camper Solar Pro'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Configuración de Sistema
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Configuración del Sistema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: capacidadBateriaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Capacidad Batería (Ah)', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextField(
                      controller: potenciaSolarCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Paneles Solares (W)', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextField(
                      controller: boosterCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Booster Alternador (A)', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Resultados Globales
            Card(
              color: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Resumen de Autonomía y Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Divider(color: Colors.white30),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('Consumo Diario', '${consumoTotalWhDia.toStringAsFixed(0)} Wh'),
                        _buildMetricCol('Autonomía', '${diasAutonomia.toStringAsFixed(1)} días'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      balanceEnergetico >= 0 
                        ? '¡Sistema Autosuficiente! Sobran ${balanceEnergetico.toStringAsFixed(0)} Wh/día'
                        : 'Déficit energético de ${balanceEnergetico.abs().toStringAsFixed(0)} Wh/día',
                      style: TextStyle(color: balanceEnergetico >= 0 ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Preajustes rápidos
            const Text('Preajustes Rápidos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: preajustes.length,
                itemBuilder: (context, index) {
                  final p = preajustes[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: Icon(p['icon'] as IconData, size: 16, color: Colors.white),
                      label: Text(p['nombre'] as String, style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: const Color(0xFF334155),
                      onPressed: () {
                        setState(() {
                          nombreCtrl.text = p['nombre'] as String;
                          potenciaCtrl.text = (p['potencia'] as double).toString();
                          horasCtrl.text = (p['horas'] as double).toString();
                          usaInversor = p['inv'] as bool;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Formulario para añadir dispositivo
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Añadir Consumidor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre del aparato', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                    ),
                    TextField(
                      controller: potenciaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Potencia (W)', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                    ),
                    TextField(
                      controller: horasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Horas de uso al día', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                    ),
                    SwitchListTile(
                      title: const Text('¿Usa Inversor 220V?', style: TextStyle(color: Colors.white70)),
                      value: usaInversor,
                      onChanged: (val) => setState(() => usaInversor = val),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _agregarAparato,
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir a la lista'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Listado de aparatos añadidos
            const Text('Dispositivos Conectados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: aparatos.length,
              itemBuilder: (context, index) {
                final aparato = aparatos[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    title: Text(aparato.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${aparato.potenciaWh}W × ${aparato.horasUso}h/día = ${aparato.consumoTotalDiario.toStringAsFixed(0)} Wh/día\nInversor: ${aparato.usaInversor ? "Sí" : "No"}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _eliminarAparato(index),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
