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
  double batteryCapacity = 150; // Ah
  double solarPanels = 350; // W
  double boosterAlternator = 30; // A
  double dailyConsumption = 1175; // Wh
  
  // Tipos de batería y su factor de profundidad de descarga útil segura
  String batteryType = 'Litio (LiFePO4)';
  final Map<String, double> batteryEfficiencyMap = {
    'Litio (LiFePO4)': 0.90, // 90% descarga útil segura
    'AGM': 0.50,             // 50% descarga útil segura
    'Gel': 0.50,             // 50% descarga útil segura
    'Ácido-Plomo / Estándar': 0.40, // 40% descarga útil segura
  };

  @override
  Widget build(BuildContext context) {
    double usableDepth = batteryEfficiencyMap[batteryType] ?? 0.50;
    
    // Cálculo de generación y balance energético
    double dailySolarGeneration = solarPanels * 4.5; // 4.5 horas sol pico estimadas
    double totalDailyEnergy = dailySolarGeneration + (boosterAlternator * 1.5 * 12); 
    double netBalance = totalDailyEnergy - dailyConsumption;
    
    // Autonomía real basada en la tecnología de la batería y su profundidad de descarga útil
    double usableBatteryWh = (batteryCapacity * 12) * usableDepth;
    double autonomyDays = usableBatteryWh / dailyConsumption;

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
            // Ilustración Interactiva de la Autocaravana y Telemetría
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
                      const Text('Tu Sistema Camper', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text('${solarPanels.toInt()}W', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/app_icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Batería: ${batteryCapacity.toInt()} Ah ($batteryType)',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Configuración del Sistema
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
                  // Selector de Tipo de Batería
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
                  _buildSliderField('Capacidad Batería (Ah)', batteryCapacity, 50, 400, (val) {
                    setState(() => batteryCapacity = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField('Paneles Solares (W)', solarPanels, 50, 1000, (val) {
                    setState(() => solarPanels = val);
                  }),
                  const Divider(color: Colors.white12),
                  _buildSliderField('Booster Alternador (A)', boosterAlternator, 0, 100, (val) {
                    setState(() => boosterAlternator = val);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Resumen de Autonomía
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
          ],
        ),
      ),
    );
  }

  Widget _buildSliderField(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text('${value.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min) ~/ 5,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
