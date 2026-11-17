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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primarySwatch: Colors.blue,
      ),
      home: const CamperHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CamperHomePage extends StatefulWidget {
  const CamperHomePage({super.key});

  @override
  State<CamperHomePage> createState() => _CamperHomePageState();
}

class _CamperHomePageState extends State<CamperHomePage> {
  // Variables reactivas de configuración idénticas al simulador
  double batteryCapacity = 150.0; // Ah
  double solarPanels = 350.0; // W
  double sunHours = 4.0; // Horas de sol pico diarias
  double boosterAlternator = 30.0; // A
  double drivingHours = 1.5; // Horas de conducción diarias
  
  // Tipos de batería y su factor de profundidad de descarga útil segura
  String batteryType = 'Litio (LiFePO4)';
  final Map<String, double> batteryEfficiencyMap = {
    'Litio (LiFePO4)': 0.90, // 90% descarga útil
    'AGM': 0.50,             // 50% descarga útil
    'Gel': 0.50,             // 50% descarga útil
    'Ácido-Plomo / Estándar': 0.40, // 40% descarga útil
  };

  // Lista de consumidores eléctricos
  var consumers = [
    {'name': 'Nevera de compresor', 'power': 45.0, 'hours': 24.0},
    {'name': 'Calefacción estacionaria', 'power': 40.0, 'hours': 8.0},
    {'name': 'Luces LED y USB', 'power': 15.0, 'hours': 5.0},
  ];

  // Controladores para añadir nuevos consumidores
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _powerController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _powerController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _addConsumer() {
    if (_nameController.text.isNotEmpty &&
        _powerController.text.isNotEmpty &&
        _hoursController.text.isNotEmpty) {
      setState(() {
        consumers.add({
          'name': _nameController.text,
          'power': double.tryParse(_powerController.text) ?? 10.0,
          'hours': double.tryParse(_hoursController.text) ?? 1.0,
        });
        _nameController.clear();
        _powerController.clear();
        _hoursController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double usableDepth = batteryEfficiencyMap[batteryType] ?? 0.50;
    
    // Cálculo de consumo diario total en Wh
    double dailyConsumption = consumers.fold(0.0, (sum, item) {
      double p = (item['power'] as num).toDouble();
      double h = (item['hours'] as num).toDouble();
      return sum + (p * h);
    });

    // Cálculos energéticos detallados
    double dailySolarGeneration = solarPanels * sunHours; 
    double dailyAlternatorGeneration = boosterAlternator * drivingHours * 12.0; // A * h * 12V = Wh
    double totalInput = dailySolarGeneration + dailyAlternatorGeneration; 
    double netBalance = totalInput - dailyConsumption;
    double totalBatteryWh = batteryCapacity * 12.0;
    
    // Autonomía real basada en la tecnología de la batería
    double usableBatteryWh = totalBatteryWh * usableDepth;
    double autonomyDays = dailyConsumption > 0 ? usableBatteryWh / dailyConsumption : 0;
    bool isSelfSufficient = netBalance >= 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.solar_power, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Camper Solar Pro', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TARJETA PRINCIPAL: ESQUEMA GRÁFICO IDÉNTICO AL SIMULADOR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  // Cabecera con estado de autosuficiencia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Camper Solar Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Esquema Energético en Tiempo Real', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelfSufficient ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelfSufficient ? Colors.greenAccent : Colors.orangeAccent),
                        ),
                        child: Text(
                          isSelfSufficient ? 'Autosuficiente' : 'Déficit',
                          style: TextStyle(color: isSelfSufficient ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Telemetría y Entrada Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TELEMETRÍA DEL SISTEMA (${batteryType.toUpperCase()})', style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withOpacity(0.4)),
                        ),
                        child: Text('Entrada: +${totalInput.toInt()} Wh/día', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // CONTENEDOR GRÁFICO CON LA ILUSTRACIÓN DE LA AUTOCARAVANA CON CAPUCHINA
                  Container(
                    height: 250,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Stack(
                      children: [
                        // Sol y haz de luz arriba a la izquierda
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wb_sunny, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text('SOL: ${sunHours}h sol/día', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        // Paneles Solares arriba a la derecha
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              'PANELES: ${solarPanels.toInt()}W\nGen: +${dailySolarGeneration.toInt()} Wh/d',
                              style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),

                        // ILUSTRACIÓN CENTRAL DE LA AUTOCARAVANA CON CAPUCHINA Y BATERÍA EXTERNA (Dibujo CustomPaint)
                        Center(
                          child: CustomPaint(
                            size: const Size(280, 160),
                            painter: CamperVanPainter(),
                          ),
                        ),

                        // Consumo interno flotante en el lateral
                        Positioned(
                          top: 115,
                          left: 110,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                            ),
                            child: Text(
                              'CONSUMO\n${dailyConsumption.toInt()} Wh/d',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Booster flotante en la cabina
                        Positioned(
                          top: 105,
                          right: 18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Text(
                              'BOOSTER DC-DC\n${boosterAlternator.toInt()}A (+${dailyAlternatorGeneration.toInt()}Wh)',
                              style: const TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Datos de Batería flotantes sobre su icono inferior
                        Positioned(
                          bottom: 2,
                          left: 65,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.greenAccent),
                            ),
                            child: Text(
                              'BATERÍA: ${batteryCapacity.toInt()} Ah (${totalBatteryWh.toInt()} Wh)',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Fila de Resumen Rápido inferior
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricSummaryBox('Batería', '${totalBatteryWh.toInt()} Wh', Colors.greenAccent),
                      _buildMetricSummaryBox('Solar/día', '+${dailySolarGeneration.toInt()} Wh', Colors.amber),
                      _buildMetricSummaryBox('Booster/día', '+${dailyAlternatorGeneration.toInt()} Wh', Colors.blueAccent),
                      _buildMetricSummaryBox('Gasto/día', '-${dailyConsumption.toInt()} Wh', Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // TARJETA DE CONFIGURACIÓN DEL SISTEMA (Sliders)
            const Text('Configuración del Sistema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de Batería', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButton<String>(
                      value: batteryType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      underline: const SizedBox(),
                      items: batteryEfficiencyMap.keys.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => batteryType = newValue);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  _buildSliderField('Capacidad Batería (Ah)', batteryCapacity, 50, 400, 5.0, (val) {
                    setState(() => batteryCapacity = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField('Paneles Solares (W)', solarPanels, 50, 1000, 25.0, (val) {
                    setState(() => solarPanels = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField('Horas de Sol Pico (h/día)', sunHours, 1.0, 8.0, 0.5, (val) {
                    setState(() => sunHours = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField('Booster Alternador (A)', boosterAlternator, 0, 100, 5.0, (val) {
                    setState(() => boosterAlternator = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField('Horas de Conducción (h/día)', drivingHours, 0.0, 6.0, 0.5, (val) {
                    setState(() => drivingHours = val);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // RESUMEN DE AUTONOMÍA Y BALANCE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Resumen de Autonomía y Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Consumo Diario', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${dailyConsumption.toInt()} Wh', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Autonomía Útil', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${autonomyDays.toStringAsFixed(1)} días', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    netBalance >= 0 ? '¡Sistema Autosuficiente! Sobran ${netBalance.toInt()} Wh/día' : 'Déficit energético diario de ${netBalance.abs().toInt()} Wh',
                    style: TextStyle(color: netBalance >= 0 ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LISTA DE CONSUMIDORES
            const Text('Consumidores Conectados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: consumers.length,
              itemBuilder: (context, index) {
                final item = consumers[index];
                final String name = item['name'] as String;
                final double power = (item['power'] as num).toDouble();
                final double hours = (item['hours'] as num).toDouble();
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${power.toInt()}W · ${hours.toInt()}h/día (${(power * hours).toInt()} Wh/día)'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          consumers.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // AÑADIR CONSUMIDOR
            const Text('Añadir Consumidor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del aparato'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _powerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Potencia (W)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Horas de uso al día'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    onPressed: _addConsumer,
                    child: const Text('Añadir a la lista'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSummaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSliderField(String label, double value, double min, double max, double step, ValueChanged<double> onChanged) {
    int divisions = ((max - min) ~/ step);
    if (divisions <= 0) divisions = 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(value == value.toInt() ? '${value.toInt()}' : value.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// PAINTER VECTORIAL PARA DIBUJAR LA AUTOCARAVANA DE CAPUCHINA CON BATERÍA DE CELDAS EXTERNA
class CamperVanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Escala del dibujo
    final double left = size.width * 0.15;
    final double top = size.height * 0.35;

    // Pinturas
    final Paint bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final Paint solarPaint = Paint()
      ..color = const Color(0xFF2E3B4E)
      ..style = PaintingStyle.fill;

    final Paint solarLinePaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Paint windowPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    // 1. DIBUJO DEL SOL ARRIBA A LA IZQUIERDA
    final Offset sunCenter = Offset(left - 15, top - 25);
    canvas.drawCircle(sunCenter, 14, Paint()..color = const Color(0xFFFEF08A).withOpacity(0.3));
    canvas.drawCircle(sunCenter, 8, Paint()..color = const Color(0xFFFBBF24));
    
    // Rayos de Sol
    final Paint rayPaint = Paint()..color = const Color(0xFFFBBF24)..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      final double angle = i * 3.14159 / 4;
      canvas.drawLine(
        Offset(sunCenter.dx + 11 * MathCos(angle), sunCenter.dy + 11 * MathSin(angle)),
        Offset(sunCenter.dx + 16 * MathCos(angle), sunCenter.dy + 16 * MathSin(angle)),
        rayPaint,
      );
    }

    // 2. DIBUJO DE LA AUTOCARAVANA CON CAPUCHINA (perfil exacto)
    final Path vanPath = Path()
      ..moveTo(left + 15, top + 55) // Cabina delantera inferior
      ..lineTo(left + 35, top + 55)
      ..quadraticBezierTo(left + 45, top + 55, left + 47, top + 45) // Paso de rueda delantero
      ..lineTo(left + 65, top + 45)
      ..quadraticBezierTo(left + 67, top + 55, left + 77, top + 55)
      ..lineTo(left + 125, top + 55) // Lateral inferior
      ..quadraticBezierTo(left + 135, top + 55, left + 137, top + 45) // Paso de rueda trasero
      ..lineTo(left + 155, top + 45)
      ..quadraticBezierTo(left + 157, top + 55, left + 167, top + 55)
      ..lineTo(left + 185, top + 55) // Trasera inferior
      ..lineTo(left + 185, top + 15) // Puerta / Trasera vertical
      ..lineTo(left + 175, top + 15)
      ..lineTo(left + 175, top - 2)   // Techo trasero alto
      ..lineTo(left + 60, top - 2)    // Techo superior plano
      ..cubicTo(left + 50, top - 2, left + 20, top - 5, left + 25, top + 12) // Capuchina delantera (curva característica)
      ..lineTo(left + 50, top + 12)   // Base de la capuchina
      ..lineTo(left + 35, top + 35)   // Capó inclinado
      ..quadraticBezierTo(left + 15, top + 45, left + 15, top + 55)
      ..close();

    canvas.drawPath(vanPath, bodyPaint);
    canvas.drawPath(vanPath, outlinePaint);

    // 3. VENTANAS Y PUERTA
    // Ventana delantera (cabina)
    final Path cabinWin = Path()
      ..moveTo(left + 33, top + 26)
      ..lineTo(left + 48, top + 26)
      ..lineTo(left + 48, top + 42)
      ..lineTo(left + 26, top + 42)
      ..close();
    canvas.drawPath(cabinWin, windowPaint);
    canvas.drawPath(cabinWin, outlinePaint);

    // Ventana trasera
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + 80, top + 6, 45, 16), const Radius.circular(4)), windowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + 80, top + 6, 45, 16), const Radius.circular(4)), outlinePaint);

    // Portabicicletas / Rueda trasera de repuesto
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left + 185, top + 22, 6, 20), const Radius.circular(2)), windowPaint);

    // 4. PANEL SOLAR INCLINADO EN EL TECHO
    final Path panelPath = Path()
      ..moveTo(left + 72, top - 2)
      ..lineTo(left + 148, top - 2)
      ..lineTo(left + 138, top - 18)
      ..lineTo(left + 82, top - 18)
      ..close();
    canvas.drawPath(panelPath, solarPaint);
    canvas.drawPath(panelPath, solarLinePaint);

    // Haz de luz y flechas de energía verdes (estilo figma)
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final Path sunBeam = Path()
      ..moveTo(sunCenter.dx, sunCenter.dy)
      ..lineTo(left + 70, top - 18)
      ..lineTo(left + 100, top - 18)
      ..close();
    canvas.drawPath(sunBeam, glowPaint);

    // 5. RUEDAS
    final Paint wheelPaint = Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.fill;
    final Paint rimPaint = Paint()..color = Colors.white70..style = PaintingStyle.fill;
    
    // Delantera
    canvas.drawCircle(Offset(left + 56, top + 52), 12, wheelPaint);
    canvas.drawCircle(Offset(left + 56, top + 52), 12, outlinePaint);
    canvas.drawCircle(Offset(left + 56, top + 52), 4, rimPaint);
    
    // Trasera
    canvas.drawCircle(Offset(left + 146, top + 52), 12, wheelPaint);
    canvas.drawCircle(Offset(left + 146, top + 52), 12, outlinePaint);
    canvas.drawCircle(Offset(left + 146, top + 52), 4, rimPaint);

    // 6. ICONO DE BATERÍA DE CELDAS HORIZONTAL EXTERNA (abajo en el centro)
    final double batX = left + 45;
    final double batY = top + 80;
    
    // Cuerpo de la batería
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(batX, batY, 80, 26), const Radius.circular(5)), Paint()..color = const Color(0xFF021E17));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(batX, batY, 80, 26), const Radius.circular(5)), Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.stroke..strokeWidth = 2);
    // Borne positivo
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(batX + 80, batY + 6, 4, 14), const Radius.circular(2)), Paint()..color = const Color(0xFF10B981));

    // Celdas de colores de carga
    canvas.drawRect(Rect.fromLTWH(batX + 6, batY + 4, 14, 18), Paint()..color = const Color(0xFFEF4444)); // Rojo
    canvas.drawRect(Rect.fromLTWH(batX + 24, batY + 4, 14, 18), Paint()..color = const Color(0xFFFBBF24)); // Amarillo
    canvas.drawRect(Rect.fromLTWH(batX + 42, batY + 4, 14, 18), Paint()..color = const Color(0xFF10B981)); // Verde
    canvas.drawRect(Rect.fromLTWH(batX + 60, batY + 4, 14, 18), Paint()..color = const Color(0xFF10B981)); // Verde

    // 7. FLECHAS DE FLUJO DE ENERGÍA (Verdes de image_6.png)
    final Paint arrowPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    
    // Desde el panel solar hacia abajo (interna)
    canvas.drawLine(Offset(left + 110, top - 2), Offset(left + 110, top + 22), arrowPaint);
    _drawArrowHeadDown(canvas, Offset(left + 110, top + 22), arrowPaint);

    // Desde la furgoneta hacia la batería (inferior)
    canvas.drawLine(Offset(left + 85, top + 54), Offset(left + 85, batY - 1), arrowPaint);
    _drawArrowHeadDown(canvas, Offset(left + 85, batY - 1), arrowPaint);

    // Desde el booster hacia la furgoneta
    canvas.drawLine(Offset(left + 160, top + 15), Offset(left + 145, top + 15), arrowPaint);
    _drawArrowHeadLeft(canvas, Offset(left + 145, top + 15), arrowPaint);
  }

  // Funciones trigonométricas inline para evitar dependencias
  double MathCos(double angle) {
    return 1.0 - (angle*angle)/2.0 + (angle*angle*angle*angle)/24.0;
  }
  double MathSin(double angle) {
    return angle - (angle*angle*angle)/6.0 + (angle*angle*angle*angle*angle)/120.0;
  }

  void _drawArrowHeadDown(Canvas canvas, Offset point, Paint paint) {
    final Path path = Path()
      ..moveTo(point.dx - 4, point.dy - 6)
      ..lineTo(point.dx, point.dy)
      ..lineTo(point.dx + 4, point.dy - 6);
    canvas.drawPath(path, paint);
  }

  void _drawArrowHeadLeft(Canvas canvas, Offset point, Paint paint) {
    final Path path = Path()
      ..moveTo(point.dx + 6, point.dy - 4)
      ..lineTo(point.dx, point.dy)
      ..lineTo(point.dx + 6, point.dy + 4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
