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
  double sunHours = 4.5; // Horas de sol pico diarias
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

    // Cálculos energéticos detallados (Generación Solar + Alternador/Booster)
    double dailySolarGeneration = solarPanels * sunHours; 
    double dailyAlternatorGeneration = boosterAlternator * drivingHours * 12.0; // A * h * 12V = Wh
    double totalDailyEnergy = dailySolarGeneration + dailyAlternatorGeneration; 
    double netBalance = totalDailyEnergy - dailyConsumption;
    
    // Autonomía real basada en la tecnología de la batería y su descarga útil
    double usableBatteryWh = (batteryCapacity * 12.0) * usableDepth;
    double autonomyDays = dailyConsumption > 0 ? usableBatteryWh / dailyConsumption : 0;

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
            // Esquema Visual de la Autocaravana en tiempo real (Idéntico al simulador)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Esquema del Sistema Camper', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('${dailySolarGeneration.toInt()} Wh/día', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car, color: Colors.blueAccent, size: 36),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Autocaravana en Ruta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Booster: ${boosterAlternator.toInt()}A (${drivingHours.toStringAsFixed(1)}h conducción)', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTelemetricBadge(Icons.battery_charging_full, 'Batería', '${batteryCapacity.toInt()} Ah', Colors.greenAccent),
                            _buildTelemetricBadge(Icons.bolt, 'Tecnología', batteryType.split(' ')[0], Colors.blueAccent),
                            _buildTelemetricBadge(Icons.electric_bolt, 'Balance Neto', '${netBalance.toInt()} Wh', netBalance >= 0 ? Colors.greenAccent : Colors.orangeAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Configuración del Sistema (Sliders y desplegables completos)
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

            // Resumen de Autonomía y Balance
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
                    netBalance >= 0 ? '¡Sistema Autosuficiente! Sobran ${netBalance.toInt()} Wh/día' : 'Déficit energético diario',
                    style: TextStyle(color: netBalance >= 0 ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lista de Consumidores
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

            // Añadir Consumidor
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

  Widget _buildTelemetricBadge(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
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
