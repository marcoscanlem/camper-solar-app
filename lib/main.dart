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
  // Variables reactivas de configuración
  double batteryCapacity = 150.0; // Ah
  double solarPanels = 350.0; // W
  double sunHours = 4.0; // Horas de sol pico diarias
  double boosterAlternator = 30.0; // A
  double drivingHours = 1.0; // Horas de conducción diarias

  // Tipos de batería y su factor de profundidad de descarga útil segura
  String batteryType = 'Litio (LiFePO4)';
  final Map<String, double> batteryEfficiencyMap = {
    'Litio (LiFePO4)': 0.90,
    'AGM': 0.50,
    'Gel': 0.50,
    'Ácido-Plomo / Estándar': 0.40,
  };

  // Lista de consumidores eléctricos
  var consumers = [
    {'name': 'Nevera de compresor', 'power': 45.0, 'hours': 24.0},
    {'name': 'Calefacción estacionaria', 'power': 12.0, 'hours': 8.0},
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
    double nominalVoltage = batteryType == 'Litio (LiFePO4)' ? 12.8 : 12.0;

    // Cálculo de consumo diario total en Wh
    double dailyConsumption = consumers.fold(0.0, (sum, item) {
      double p = (item['power'] as num).toDouble();
      double h = (item['hours'] as num).toDouble();
      return sum + (p * h);
    });

    // Cálculos energéticos detallados
    double dailySolarGeneration = solarPanels * sunHours;
    double boosterWatts = boosterAlternator * nominalVoltage;
    double dailyAlternatorGeneration = boosterWatts * drivingHours;
    double totalInput = dailySolarGeneration + dailyAlternatorGeneration;
    double netBalance = totalInput - dailyConsumption;
    double totalBatteryWh = batteryCapacity * nominalVoltage;

    // Autonomía real basada en la tecnología de la batería
    double usableBatteryWh = totalBatteryWh * usableDepth;
    double autonomyDays =
        dailyConsumption > 0 ? usableBatteryWh / dailyConsumption : 0;
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
              child: const Icon(Icons.directions_bus,
                  color: Colors.lightBlueAccent, size: 26),
            ),
            const SizedBox(width: 12),
            const Text('Camper Solar Pro',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TARJETA PRINCIPAL: ESQUEMA GRÁFICO IDÉNTICO AL SIMULADOR WEB
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Camper Solar Pro',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text('Esquema Energético en Tiempo Real',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelfSufficient
                              ? const Color(0xFF064E3B)
                              : const Color(0xFF7C2D12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelfSufficient
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent),
                        ),
                        child: Text(
                          isSelfSufficient ? 'Autosuficiente' : 'Déficit',
                          style: TextStyle(
                              color: isSelfSufficient
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Telemetría y Entrada Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'TELEMETRÍA DEL SISTEMA\n(${nominalVoltage}V ${batteryType.split(' ')[0].toUpperCase()})',
                          style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Entrada: +${totalInput.toInt()} Wh/día',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // LIENZO DE LA AUTOCARAVANA CON SOL, PANELES, FLUJOS Y ETIQUETAS
                  Container(
                    height: 245,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1324),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // Dibujo vectorial de la camper, sol, placas y rayos
                            CustomPaint(
                              size: Size(
                                  constraints.maxWidth, constraints.maxHeight),
                              painter: RealisticCamperPainter(),
                            ),

                            // Etiqueta SOL arriba a la derecha
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.amber.withOpacity(0.6)),
                                ),
                                child: Text(
                                  'SOL: ${sunHours.toStringAsFixed(1)}h pico/día',
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                            // Etiqueta PANELES arriba a la izquierda
                            Positioned(
                              top: 32,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF38BDF8)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'PANELES: ${solarPanels.toInt()} W',
                                      style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Generación: +${dailySolarGeneration.toInt()} Wh/día',
                                      style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Etiqueta CONSUMO en el centro
                            Positioned(
                              top: 118,
                              left: constraints.maxWidth * 0.34,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1B2E),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.redAccent),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'CONSUMO',
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${dailyConsumption.toInt()} Wh/d',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Etiqueta BATERÍA abajo a la izquierda
                            Positioned(
                              bottom: 42,
                              left: 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF062C24),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.greenAccent),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${batteryCapacity.toInt()} Ah',
                                      style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${totalBatteryWh.toInt()} Wh',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Etiqueta BOOSTER DC-DC abajo a la derecha
                            Positioned(
                              bottom: 42,
                              right: 26,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'BOOSTER DC-DC',
                                      style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${boosterAlternator.toInt()} A (${boosterWatts.toInt()} W)',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Ruta: +${dailyAlternatorGeneration.toInt()} Wh/d',
                                      style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Fila de 4 tarjetas inferiores idéntica al simulador
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricSummaryBox('Batería',
                            '${totalBatteryWh.toInt()} Wh', const Color(0xFF38BDF8)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildMetricSummaryBox('Solar/día',
                            '+${dailySolarGeneration.toInt()} Wh', Colors.amber),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildMetricSummaryBox(
                            'Booster/día',
                            '+${dailyAlternatorGeneration.toInt()} Wh',
                            Colors.greenAccent),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildMetricSummaryBox('Gasto/día',
                            '-${dailyConsumption.toInt()} Wh', Colors.redAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // TARJETA DE CONFIGURACIÓN DEL SISTEMA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Configuración del Sistema',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                  ),
                  child: Text('Nominal ${nominalVoltage}V',
                      style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
                  const Text('Tipo de Batería',
                      style: TextStyle(color: Colors.white70)),
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
                          child: Text(type,
                              style: const TextStyle(color: Colors.white)),
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
                  _buildSliderField('Capacidad Batería (Ah)', batteryCapacity,
                      50, 400, 5.0, (val) {
                    setState(() => batteryCapacity = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField(
                      'Paneles Solares (W)', solarPanels, 50, 1000, 25.0,
                      (val) {
                    setState(() => solarPanels = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField(
                      'Horas de Sol Pico (h/día)', sunHours, 1.0, 8.0, 0.5,
                      (val) {
                    setState(() => sunHours = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField('Booster Alternador (A)',
                      boosterAlternator, 0, 100, 5.0, (val) {
                    setState(() => boosterAlternator = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField('Horas de Conducción (h/día)',
                      drivingHours, 0.0, 6.0, 0.5, (val) {
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
                  const Text('Resumen de Autonomía y Balance',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Consumo Diario',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text('${dailyConsumption.toInt()} Wh',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Autonomía Útil',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text('${autonomyDays.toStringAsFixed(1)} días',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    netBalance >= 0
                        ? '¡Sistema Autosuficiente! Sobran ${netBalance.toInt()} Wh/día'
                        : 'Déficit energético diario de ${netBalance.abs().toInt()} Wh',
                    style: TextStyle(
                        color: netBalance >= 0
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LISTA DE CONSUMIDORES
            const Text('Consumidores Conectados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${power.toInt()}W · ${hours.toInt()}h/día (${(power * hours).toInt()} Wh/día)'),
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
            const Text('Añadir Consumidor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    decoration:
                        const InputDecoration(labelText: 'Nombre del aparato'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _powerController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Potencia (W)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Horas de uso al día'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSliderField(String label, double value, double min, double max,
      double step, ValueChanged<double> onChanged) {
    int divisions = ((max - min) ~/ step);
    if (divisions <= 0) divisions = 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
                value == value.toInt()
                    ? '${value.toInt()}'
                    : value.toStringAsFixed(1),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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

// PINTOR VECTORIAL DETALLADO DE LA AUTOCARAVANA CAMPER
class RealisticCamperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Sol brillante arriba a la derecha
    final Offset sunCenter = Offset(w * 0.84, h * 0.25);
    canvas.drawCircle(
      sunCenter,
      24,
      Paint()..color = const Color(0xFFFBBF24).withOpacity(0.18),
    );
    canvas.drawCircle(
      sunCenter,
      14,
      Paint()..color = const Color(0xFFFBBF24),
    );

    // 2. Rayos discontinuos desde el sol hacia los paneles
    final Paint rayPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
        canvas, Offset(sunCenter.dx - 16, sunCenter.dy + 4), Offset(w * 0.56, h * 0.35), rayPaint);
    _drawDashedLine(
        canvas, Offset(sunCenter.dx - 14, sunCenter.dy + 10), Offset(w * 0.58, h * 0.40), rayPaint);

    // 3. Coordenadas base de la furgoneta camper
    final double leftX = w * 0.12;
    final double rightX = w * 0.88;
    final double roofY = h * 0.41;
    final double floorY = h * 0.78;
    final double hoodStartX = w * 0.65;
    final double hoodY = h * 0.61;

    // Carrocería blanca principal
    final Path vanBody = Path()
      ..moveTo(leftX + 12, roofY)
      ..lineTo(hoodStartX - 15, roofY)
      ..quadraticBezierTo(hoodStartX, roofY, hoodStartX + 8, roofY + 12)
      ..lineTo(rightX - 24, hoodY)
      ..quadraticBezierTo(rightX - 4, hoodY + 2, rightX, hoodY + 18)
      ..lineTo(rightX, floorY - 6)
      ..quadraticBezierTo(rightX, floorY, rightX - 8, floorY)
      ..lineTo(leftX + 8, floorY)
      ..quadraticBezierTo(leftX, floorY, leftX, floorY - 8)
      ..lineTo(leftX, roofY + 12)
      ..quadraticBezierTo(leftX, roofY, leftX + 12, roofY)
      ..close();

    canvas.drawPath(vanBody, Paint()..color = const Color(0xFFF8FAFC));

    // Franja inferior azul (estilo camper)
    canvas.save();
    canvas.clipPath(vanBody);
    canvas.drawRect(
      Rect.fromLTRB(leftX, floorY - 16, rightX, floorY),
      Paint()..color = const Color(0xFF0284C7),
    );
    // Línea decorativa lateral
    canvas.drawRect(
      Rect.fromLTRB(leftX, floorY - 20, rightX, floorY - 18),
      Paint()..color = const Color(0xFF38BDF8),
    );
    canvas.restore();

    // Contorno suave de la furgoneta
    canvas.drawPath(
      vanBody,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 4. Ventana trasera/lateral oscura
    final RRect sideWindow = RRect.fromRectAndRadius(
      Rect.fromLTRB(leftX + 14, roofY + 10, leftX + (hoodStartX - leftX) * 0.52, roofY + 34),
      const Radius.circular(5),
    );
    canvas.drawRRect(sideWindow, Paint()..color = const Color(0xFF1E293B));

    // 5. Ventana de cabina delantera
    final Path cabinWindow = Path()
      ..moveTo(hoodStartX - 18, roofY + 9)
      ..lineTo(hoodStartX - 3, roofY + 9)
      ..lineTo(rightX - 28, hoodY - 2)
      ..lineTo(hoodStartX - 18, hoodY - 2)
      ..close();
    canvas.drawPath(cabinWindow, Paint()..color = const Color(0xFF1E293B));

    // Faro delantero amarillo
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(rightX - 9, hoodY + 12, rightX, hoodY + 21),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFBBF24),
    );

    // 6. Paneles solares inclinados en perspectiva sobre el techo
    final Paint panelFill = Paint()..color = const Color(0xFF1D4ED8);
    final Paint panelBorder = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Panel 1
    final Path panel1 = Path()
      ..moveTo(leftX + 26, roofY - 2)
      ..lineTo(leftX + 82, roofY - 2)
      ..lineTo(leftX + 94, roofY - 14)
      ..lineTo(leftX + 38, roofY - 14)
      ..close();
    canvas.drawPath(panel1, panelFill);
    canvas.drawPath(panel1, panelBorder);

    // Panel 2
    final Path panel2 = Path()
      ..moveTo(leftX + 90, roofY - 2)
      ..lineTo(leftX + 146, roofY - 2)
      ..lineTo(leftX + 158, roofY - 14)
      ..lineTo(leftX + 102, roofY - 14)
      ..close();
    canvas.drawPath(panel2, panelFill);
    canvas.drawPath(panel2, panelBorder);

    // 7. Líneas de conexión internas (Flujo de energía)
    // Línea amarilla de paneles a batería
    _drawDashedLine(
      canvas,
      Offset(leftX + 55, roofY - 2),
      Offset(leftX + 55, floorY - 24),
      Paint()
        ..color = const Color(0xFFFBBF24)
        ..strokeWidth = 1.6,
    );
    // Línea roja de batería a consumo
    _drawDashedLine(
      canvas,
      Offset(leftX + 85, floorY - 28),
      Offset(w * 0.45, roofY + 34),
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 1.6,
    );

    // 8. Suelo / Carretera sutil bajo las ruedas
    canvas.drawLine(
      Offset(w * 0.08, floorY + 14),
      Offset(w * 0.92, floorY + 14),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 1.5,
    );

    // 9. Ruedas detalladas con pasos de rueda
    _drawWheel(canvas, Offset(leftX + 42, floorY + 1));
    _drawWheel(canvas, Offset(rightX - 44, floorY + 1));
  }

  void _drawWheel(Canvas canvas, Offset center) {
    // Paso de rueda oscuro
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFF0B1324));
    // Neumático
    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Llanta metálica
    canvas.drawCircle(center, 7, Paint()..color = const Color(0xFFCBD5E1));
    // Eje central
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFF334155));
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 3.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = (Offset(dx, dy)).distance;
    if (distance == 0) return;

    final double unitX = dx / distance;
    final double unitY = dy / distance;
    double currentDistance = 0.0;

    while (currentDistance < distance) {
      final double endDistance = (currentDistance + dashWidth < distance)
          ? currentDistance + dashWidth
          : distance;
      canvas.drawLine(
        Offset(p1.dx + unitX * currentDistance, p1.dy + unitY * currentDistance),
        Offset(p1.dx + unitX * endDistance, p1.dy + unitY * endDistance),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
