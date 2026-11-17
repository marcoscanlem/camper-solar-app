import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Solar',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const SolarCalculatorScreen(),
    );
  }
}

// Definición de la clase Aparato para la calculadora solar
class Aparato {
  String nombre;
  double potenciaW;
  double horasDia;
  bool activo;
  IconData icono;

  Aparato({
    required this.nombre,
    required this.potenciaW,
    required this.horasDia,
    this.activo = true,
    this.icono = Icons.electrical_services,
  });

  double get consumoDiarioWh => activo ? (potenciaW * horasDia) : 0.0;
}

// 2. PANTALLA PRINCIPAL Y LÓGICA DE CÁLCULO
class SolarCalculatorScreen extends StatefulWidget {
  const SolarCalculatorScreen({super.key});

  @override
  State<SolarCalculatorScreen> createState() => _SolarCalculatorScreenState();
}

class _SolarCalculatorScreenState extends State<SolarCalculatorScreen> {
  // Configuración de la instalación
  int voltaje = 12; // 12V o 24V
  double capacidadAh = 200;
  double potenciaPlacasW = 400;
  final double eficienciaSolar = 0.75; // Pérdidas del sistema

  // Listado inicial de aparatos típicos en autocaravana
  final List<Aparato> aparatos = [
    Aparato(
      nombre: 'Nevera compresor 12V',
      potenciaW: 45,
      horasDia: 12,
      activo: true,
      icono: Icons.ac_unit,
    ),
    Aparato(
      nombre: 'Iluminación LED',
      potenciaW: 15,
      horasDia: 4,
      activo: true,
      icono: Icons.lightbulb,
    ),
    Aparato(
      nombre: 'Bomba de agua',
      potenciaW: 40,
      horasDia: 0.5,
      activo: true,
      icono: Icons.water_drop,
    ),
    Aparato(
      nombre: 'Carga móviles / Tablet',
      potenciaW: 15,
      horasDia: 3,
      activo: true,
      icono: Icons.phone_android,
    ),
  ];

  // Cálculos totales
  double get consumoTotalWh {
    double total = 0;
    for (var aparato in aparatos) {
      total += aparato.consumoDiarioWh;
    }
    return total;
  }

  double get consumoTotalAh => consumoTotalWh / voltaje;

  // Producción solar estimada diaria (Wh)
  double get produccionSolarWh => potenciaPlacasW * 4.5 * eficienciaSolar;

  @override
  Widget build(BuildContext context) {
    double autonomiaDias = consumoTotalWh > 0 ? (capacidadAh * voltaje * 0.5) / consumoTotalWh : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Solar Autocaravana'),
        backgroundColor: Colors.amber[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _TarjetaDato(
                    titulo: 'Consumo Diario',
                    valor: '${consumoTotalWh.toStringAsFixed(0)} Wh',
                    subtitulo: '${consumoTotalAh.toStringAsFixed(1)} Ah (${voltaje}V)',
                    colorDestacado: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TarjetaDato(
                    titulo: 'Producción Solar',
                    valor: '${produccionSolarWh.toStringAsFixed(0)} Wh',
                    subtitulo: 'Estimada diaria',
                    colorDestacado: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TarjetaDato(
              titulo: 'Autonomía Estimada',
              valor: '${autonomiaDias.toStringAsFixed(1)} días',
              subtitulo: autonomiaDias >= 2 ? 'Sistema equilibrado' : '¡Cuidado! Autonomía baja',
              colorDestacado: autonomiaDias >= 2 ? Colors.blue : Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Aparatos Conectados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: aparatos.length,
              itemBuilder: (context, index) {
                final aparato = aparatos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(aparato.icono, color: aparato.activo ? Colors.amber[800] : Colors.grey),
                    title: Text(aparato.nombre),
                    subtitle: Text('${aparato.potenciaW}W - ${aparato.horasDia}h/día'),
                    trailing: Switch(
                      value: aparato.activo,
                      onChanged: (bool value) {
                        setState(() {
                          aparato.activo = value;
                        });
                      },
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
}

// Widget auxiliar para las tarjetas de resumen
class _TarjetaDato extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final Color colorDestacado;

  const _TarjetaDato({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.colorDestacado,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorDestacado,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitulo, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
