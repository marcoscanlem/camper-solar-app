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
            // TARJETA PRINCIPAL: ESQUEMA VISUAL DE LA AUTOCARAVANA (Idéntica al simulador)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  // Cabecera de la tarjeta con estado de autosuficiencia
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

                  // Subtítulo de Telemetría y Entrada Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TELEMETRÍA (${batteryType.toUpperCase()})', style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
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

                  // Contenedor visual gráfico de la autocaravana
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        // Fila superior: Sol y Paneles
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.solar_power, color: Colors.amber, size: 22),
                                const SizedBox(width: 6),
                                Text('Paneles: ${solarPanels.toInt()}W', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.wb_sunny, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text('${sunHours}h sol/día', style: const TextStyle(color: Colors.amber, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Ilustración central esquemática de la furgoneta
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.battery_charging_full, color: Colors.greenAccent, size: 24),
                                  const SizedBox(height: 2),
                                  Text('${batteryCapacity.toInt()} Ah', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.greenAccent)),
                                  Text('${totalBatteryWh.toInt()} Wh', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                                ],
                              ),
                              const Icon(Icons.directions_car, color: Colors.blueAccent, size: 36),
                              Column(
                                children: [
                                  const Icon(Icons.bolt, color: Colors.amber, size: 24),
                                  const SizedBox(height: 2),
                                  Text('Booster ${boosterAlternator.toInt()}A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber)),
                                  Text('${dailyAlternatorGeneration.toInt()} Wh/d', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Indicador de Consumo Interno
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 6),
                            Text('Consumo Interno: ${dailyConsumption.toInt()} Wh/día', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Fila de Resumen Rápido inferior (como en el simulador)
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

            // TARJETA DE CONFIGURACIÓN DEL SISTEMA (Controles y Sliders)
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
