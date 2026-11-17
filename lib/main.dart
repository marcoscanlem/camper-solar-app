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

                  // CONTENEDOR GRÁFICO CON LA ILUSTRACIÓN DE LA AUTOCARAVANA
                  Container(
                    height: 210,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Stack(
                      children: [
                        // Sol y Horas de Sol arriba a la derecha
                        Positioned(
                          top: 4,
                          right: 4,
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

                        // Paneles Solares arriba a la izquierda
                        Positioned(
                          top: 4,
                          left: 4,
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
                            ),
                          ),
                        ),

                        // ILUSTRACIÓN CENTRAL DE LA AUTOCARAVANA (Dibuja la furgoneta de perfil)
                        Center(
                          child: CustomPaint(
                            size: const Size(260, 110),
                            painter: CamperVanPainter(),
                          ),
                        ),

                        // Batería en la parte trasera inferior
                        Positioned(
                          bottom: 8,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.greenAccent),
                            ),
                            child: Text(
                              '${batteryCapacity.toInt()} Ah\n${totalBatteryWh.toInt()} Wh',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Consumo interno en el centro de la furgo
                        Positioned(
                          top: 85,
                          left: 95,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                            ),
                            child: Text(
                              'CONSUMO: ${dailyConsumption.toInt()} Wh/d',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        // Booster en la parte delantera inferior
                        Positioned(
                          bottom: 8,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Text(
                              'BOOSTER DC-DC\n${boosterAlternator.toInt()}A (+${dailyAlternatorGeneration.toInt()}Wh)',
                              style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
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

            // TARJETA DE CONFIGURACIÓN DEL SISTEMA
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

// PAINTER PARA DIBUJAR LA AUTOCARAVANA EXACTAMENTE IGUAL AL SIMULADOR
class CamperVanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBody = Paint()
      .-color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;

    final paintCabin = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..style = PaintingStyle.fill;

    final paintPanels = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;

    final paintPanelBorder = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintWheels = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final paintRims = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    final paintDetails = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Chasis de la furgoneta (Cuerpo principal)
    final bodyRect = Rect.fromLTWH(30, 45, 200, 45);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(12));
    canvas.drawRRect(bodyRRect, paintBody);

    // 2. Cabina delantera redondeada
    final cabinPath = Path()
      ..moveTo(200, 90)
      ..lineTo(230, 90)
      ..quadraticBezierTo(250, 90, 240, 65)
      ..lineTo(210, 45)
      ..lineTo(200, 45)
      ..close();
    canvas.drawPath(cabinPath, paintCabin);

    // 3. Ventana delantera
    final windowPath = Path()
      ..moveTo(212, 48)
      ..lineTo(232, 65)
      ..lineTo(205, 65)
      ..close();
    canvas.drawPath(windowPath, Paint()..color = const Color(0xFF0F172A));

    // 4. Paneles solares en el techo
    final panelRect = Rect.fromLTWH(50, 32, 130, 13);
    canvas.drawRect(panelRect, paintPanels);
    canvas.drawRect(panelRect, paintPanelBorder);

    // 5. Ruedas
    canvas.drawCircle(const Offset(75, 95), 14, paintWheels);
    canvas.drawCircle(const Offset(75, 95), 6, paintRims);

    canvas.drawCircle(const Offset(205, 95), 14, paintWheels);
    canvas.drawCircle(const Offset(205, 95), 6, paintRims);

    // 6. Detalles de puerta y líneas
    canvas.drawLine(const Offset(130, 45), const Offset(130, 90), paintDetails);
    canvas.drawLine(const Offset(170, 60), const Offset(190, 60), paintDetails);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
