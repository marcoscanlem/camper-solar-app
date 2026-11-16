import 'package:flutter/material.dart';

void main() {
  runApp(const CamperSolarApp());
}

class CamperSolarApp extends StatelessWidget {
  const CamperSolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camper Energy Calc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B5E20), // Verde bosque / aventura
        brightness: Brightness.light,
      ),
      home: const SolarCalculatorScreen(),
    );
  }
}

// ==========================================
// 1. MODELOS DE DATOS
// ==========================================

enum TipoBateria {
  litio('Litio (LiFePO4)', 0.90),
  agm('AGM / Gel', 0.50);

  final String nombre;
  final double profundidadDescarga; // DoD (Depth of Discharge)
  const TipoBateria(this.nombre, this.profundidadDescarga);
}

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

// ==========================================
// 2. PANTALLA PRINCIPAL Y LÓGICA DE CÁLCULO
// ==========================================

class SolarCalculatorScreen extends StatefulWidget {
  const SolarCalculatorScreen({super.key});

  @override
  State<SolarCalculatorScreen> createState() => _SolarCalculatorScreenState();
}

class _SolarCalculatorScreenState extends State<SolarCalculatorScreen> {
  // Configuración de la instalación
  int voltaje = 12; // 12V o 24V
  TipoBateria tipoBateria = TipoBateria.litio;
  double capacidadAh = 200;
  double potenciaPlacasW = 400;
  final double eficienciaSolar = 0.75; // Pérdidas por temperatura, cableado, inclinación

  // Listado inicial de aparatos típicos en autocaravana
  final List<Aparato> aparatos = [
    Aparato(
      nombre: 'Nevera compresor 12V',
      potenciaW: 45,
      horasDia: 12, // Funciona por ciclos (aprox 50% del día)
      activo: true,
      icono: Icons.kitchen,
    ),
    Aparato(
      nombre: 'Iluminación LED interior',
      potenciaW: 15,
      horasDia: 4,
      activo: true,
      icono: Icons.lightbulb_outline,
    ),
    Aparato(
      nombre: 'Bomba de agua',
      potenciaW: 60,
      horasDia: 0.3, // ~20 minutos al día
      activo: true,
      icono: Icons.water_drop_outlined,
    ),
    Aparato(
      nombre: 'Carga móviles / Portátil',
      potenciaW: 65,
      horasDia: 3,
      activo: true,
      icono: Icons.laptop_mac,
    ),
    Aparato(
      nombre: 'Calefacción estacionaria',
      potenciaW: 25,
      horasDia: 8,
      activo: false,
      icono: Icons.local_fire_department_outlined,
    ),
    Aparato(
      nombre: 'Aire acondicionado (con inversor)',
      potenciaW: 900,
      horasDia: 2,
      activo: false,
      icono: Icons.ac_unit,
    ),
  ];

  // --- FÓRMULAS ENERGÉTICAS ---

  double get consumoTotalDiarioWh {
    return aparatos.fold(0.0, (suma, item) => suma + item.consumoDiarioWh);
  }

  double get energiaUtilBateriaWh {
    return capacidadAh * voltaje * tipoBateria.profundidadDescarga;
  }

  double get diasAutonomia {
    if (consumoTotalDiarioWh <= 0) return 99.9;
    return energiaUtilBateriaWh / consumoTotalDiarioWh;
  }

  double get horasSolParaCargarConsumoDiario {
    if (potenciaPlacasW <= 0) return 0.0;
    double potenciaRealW = potenciaPlacasW * eficienciaSolar;
    return consumoTotalDiarioWh / potenciaRealW;
  }

  double get capacidadRecomendadaAh {
    const int diasObjetivo = 2;
    return (consumoTotalDiarioWh * diasObjetivo) /
        (voltaje * tipoBateria.profundidadDescarga);
  }

  // --- DIÁLOGO PARA AÑADIR APARATO PERSONALIZADO ---

  void _mostrarDialogoNuevoAparato() {
    final nombreCtrl = TextEditingController();
    final potenciaCtrl = TextEditingController();
    final horasCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir aparato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre (ej. Cafetera, TV)'),
            ),
            TextField(
              controller: potenciaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Potencia en Vatios (W)'),
            ),
            TextField(
              controller: horasCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Horas de uso al día'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              final potencia = double.tryParse(potenciaCtrl.text) ?? 0;
              final horas = double.tryParse(horasCtrl.text) ?? 0;

              if (nombre.isNotEmpty && potencia > 0 && horas > 0) {
                setState(() {
                  aparatos.add(Aparato(
                    nombre: nombre,
                    potenciaW: potencia,
                    horasDia: horas,
                    activo: true,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. INTERFAZ DE USUARIO (UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final bool autonomiaCritica = diasAutonomia < 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Solar Camper'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoAparato,
        icon: const Icon(Icons.add),
        label: const Text('Añadir aparato'),
      ),
      body: Column(
        children: [
          // PANEL DE RESULTADOS EN TIEMPO REAL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: autonomiaCritica
                  ? Colors.red.shade50
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TarjetaDato(
                      titulo: 'Autonomía',
                      valor: diasAutonomia >= 99
                          ? '∞'
                          : '${diasAutonomia.toStringAsFixed(1)} días',
                      subtitulo: diasAutonomia >= 99
                          ? 'Sin consumo'
                          : '(${(diasAutonomia * 24).toStringAsFixed(0)} horas)',
                      colorDestacado: autonomiaCritica ? Colors.red : Colors.green.shade800,
                    ),
                    _TarjetaDato(
                      titulo: 'Carga Solar',
                      valor: '${horasSolParaCargarConsumoDiario.toStringAsFixed(1)} h',
                      subtitulo: 'Horas de sol pico/día',
                      colorDestacado: Colors.orange.shade800,
                    ),
                    _TarjetaDato(
                      titulo: 'Consumo',
                      valor: '${consumoTotalDiarioWh.toStringAsFixed(0)} Wh',
                      subtitulo: 'Total diario',
                      colorDestacado: Colors.blue.shade800,
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'Batería recomendada (2 días autonomía): ${capacidadRecomendadaAh.toStringAsFixed(0)} Ah a ${voltaje}V',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // CONTENIDO DESPLAZABLE: CONFIGURACIÓN + LISTA DE APARATOS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // SECCIÓN 1: BATERÍA Y PLACAS
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. Tu Instalación Eléctrica',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<TipoBateria>(
                                value: tipoBateria,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de batería',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                ),
                                items: TipoBateria.values.map((tipo) {
                                  return DropdownMenuItem(
                                    value: tipo,
                                    child: Text(tipo.nombre, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => tipoBateria = val!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 12, label: Text('12V')),
                                ButtonSegment(value: 24, label: Text('24V')),
                              ],
                              selected: {voltaje},
                              onSelectionChanged: (Set<int> newSelection) {
                                setState(() => voltaje = newSelection.first);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Capacidad Batería: ${capacidadAh.toInt()} Ah (${energiaUtilBateriaWh.toInt()} Wh útiles)'),
                        Slider(
                          value: capacidadAh,
                          min: 50,
                          max: 600,
                          divisions: 55,
                          label: '${capacidadAh.toInt()} Ah',
                          onChanged: (val) => setState(() => capacidadAh = val),
                        ),
                        Text('Placas Solares: ${potenciaPlacasW.toInt()} W'),
                        Slider(
                          value: potenciaPlacasW,
                          min: 0,
                          max: 1200,
                          divisions: 24,
                          label: '${potenciaPlacasW.toInt()} W',
                          onChanged: (val) => setState(() => potenciaPlacasW = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  '2. Consumos y Aparatos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // SECCIÓN 2: LISTADO DE APARATOS
                ...aparatos.map((aparato) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: Icon(aparato.icono),
                            title: Text(aparato.nombre),
                            subtitle: Text(
                              '${aparato.potenciaW.toInt()} W × ${aparato.horasDia} h = ${aparato.consumoDiarioWh.toStringAsFixed(0)} Wh/día',
                            ),
                            value: aparato.activo,
                            onChanged: (val) => setState(() => aparato.activo = val),
                          ),
                          if (aparato.activo)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Text('Horas/día:', style: TextStyle(fontSize: 12)),
                                  Expanded(
                                    child: Slider(
                                      value: aparato.horasDia,
                                      min: 0.1,
                                      max: 24,
                                      divisions: 239,
                                      label: '${aparato.horasDia.toStringAsFixed(1)} h',
                                      onChanged: (val) {
                                        setState(() {
                                          aparato.horasDia = double.parse(val.toStringAsFixed(1));
                                        });
                                      },
                                    ),
                                  ),
                                  Text('${aparato.horasDia.toStringAsFixed(1)} h'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaDato extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final Color colorDestacado;

  const _TarjetaDator({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.colorDestacado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorDestacado,
          ),
        ),
        Text(subtitulo, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
