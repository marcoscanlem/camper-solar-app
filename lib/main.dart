import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const CamperSolarApp());

// ---------------------------------------------------------------------------
// Paleta y utilidades
// ---------------------------------------------------------------------------
const Color kBg = Color(0xFF0F172A);
const Color kCard = Color(0xFF1E293B);
const Color kGreen = Color(0xFF4ADE80);
const Color kAmber = Color(0xFFFBBF24);
const Color kBlue = Color(0xFF38BDF8);
const Color kRed = Color(0xFFF87171);

Color op(Color c, double o) => c.withAlpha((o * 255).round());

String fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

double? parseNum(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

const TextInputType numKeyboard =
    TextInputType.numberWithOptions(decimal: true);

class Appliance {
  String name;
  double power;
  double hours;
  Appliance(this.name, this.power, this.hours);
  double get wh => power * hours;
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------
class CamperSolarApp extends StatelessWidget {
  const CamperSolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camper Solar Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBlue,
          brightness: Brightness.dark,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: kBlue,
          inactiveTrackColor: Colors.white12,
          thumbColor: kBlue,
          overlayColor: op(kBlue, 0.15),
          tickMarkShape: SliderTickMarkShape.noTickMark,
        ),
      ),
      home: const CamperHomePage(),
    );
  }
}

class CamperHomePage extends StatefulWidget {
  const CamperHomePage({super.key});

  @override
  State<CamperHomePage> createState() => _CamperHomePageState();
}

class _CamperHomePageState extends State<CamperHomePage>
    with SingleTickerProviderStateMixin {
  // Configuración del sistema
  double batteryCapacity = 150.0; // Ah
  
  // Fuentes de energía y toggles de activación
  bool enableSolar = true;
  double solarPanels = 350.0; // W
  double sunHours = 4.0; // h sol pico

  bool enableBooster = true;
  double boosterAlternator = 30.0; // A
  double drivingHours = 1.5; // h/día

  bool enableShore230 = false; // Toma exterior 230V camping
  double shorePowerAmps = 16.0; // Amperios del cargador de 230V (ej. 16A -> ~1800W)
  double shoreHours = 6.0; // Horas conectado a 230V al día

  String batteryType = 'Litio (LiFePO4)';
  final Map<String, double> batteryEfficiencyMap = {
    'Litio (LiFePO4)': 0.90,
    'AGM': 0.50,
    'Gel': 0.50,
    'Ácido-Plomo / Estándar': 0.40,
  };

  final List<Appliance> consumers = [
    Appliance('Nevera de compresor', 45, 24),
    Appliance('Calefacción estacionaria', 40, 8),
    Appliance('Luces LED y USB', 15, 5),
  ];

  final List<Appliance> presets = [
    Appliance('TV 12V', 30, 3),
    Appliance('Portátil', 60, 4),
    Appliance('Bomba de agua', 60, 0.5),
    Appliance('Ventilador', 20, 6),
    Appliance('Router 4G', 10, 24),
    Appliance('Cargador móvil', 10, 3),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _powerController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();

  late final AnimationController _flow;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _flow.dispose();
    _nameController.dispose();
    _powerController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _addConsumer() {
    final name = _nameController.text.trim();
    final power = parseNum(_powerController.text);
    final hours = parseNum(_hoursController.text);
    if (name.isEmpty ||
        power == null ||
        hours == null ||
        power < 0 ||
        hours < 0 ||
        hours > 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los datos: nombre, potencia (W) y horas (0-24).'),
        ),
      );
      return;
    }
    setState(() {
      consumers.add(Appliance(name, power, hours));
      _nameController.clear();
      _powerController.clear();
      _hoursController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _editConsumer(int i) async {
    final c = consumers[i];
    final p = TextEditingController(text: fmt(c.power));
    final h = TextEditingController(text: fmt(c.hours));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text(c.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: p,
              keyboardType: numKeyboard,
              decoration: const InputDecoration(labelText: 'Potencia (W)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: h,
              keyboardType: numKeyboard,
              decoration: const InputDecoration(labelText: 'Horas de uso al día'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final pv = parseNum(p.text);
      final hv = parseNum(h.text);
      if (pv != null && pv >= 0 && hv != null && hv >= 0 && hv <= 24) {
        setState(() {
          c.power = pv;
          c.hours = hv;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usableDepth = batteryEfficiencyMap[batteryType] ?? 0.50;

    final dailyConsumption = consumers.fold<double>(0, (s, a) => s + a.wh);
    
    // Cálculo de aportes según estén activados
    final dailySolar = enableSolar ? (solarPanels * sunHours) : 0.0;
    final dailyAlternator = enableBooster ? (boosterAlternator * drivingHours * 12.0) : 0.0;
    
    // Energía de 230V externa (ej: cargador de batería de 230V a 12V)
    final dailyShore = enableShore230 ? (shorePowerAmps * 12.0 * shoreHours) : 0.0;

    final totalInput = dailySolar + dailyAlternator + dailyShore;
    final netBalance = totalInput - dailyConsumption;
    final totalBatteryWh = batteryCapacity * 12.0;
    final usableBatteryWh = totalBatteryWh * usableDepth;
    final autonomyDays =
        dailyConsumption > 0 ? usableBatteryWh / dailyConsumption : 0.0;
    final isSelfSufficient = netBalance >= 0;
    final coverage = dailyConsumption > 0 ? totalInput / dailyConsumption : 1.0;
    
    final soc = usableBatteryWh > 0
        ? ((usableBatteryWh + math.min(0.0, netBalance)) / usableBatteryWh)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kCard,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: op(kBlue, 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.solar_power, color: kAmber, size: 26),
            ),
            const SizedBox(width: 12),
            const Text('Camper Solar Pro',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiagramCard(
                isSelfSufficient: isSelfSufficient,
                totalInput: totalInput,
                dailySolar: dailySolar,
                dailyAlternator: dailyAlternator,
                dailyShore: dailyShore,
                dailyConsumption: dailyConsumption,
                totalBatteryWh: totalBatteryWh,
                usableBatteryWh: usableBatteryWh,
                soc: soc,
              ),
              const SizedBox(height: 16),
              _buildBalanceCard(
                dailyConsumption: dailyConsumption,
                totalInput: totalInput,
                autonomyDays: autonomyDays,
                netBalance: netBalance,
                coverage: coverage,
              ),
              const SizedBox(height: 24),
              _sectionTitle('Configuración del sistema', Icons.tune),
              _buildConfigCard(),
              const SizedBox(height: 24),
              _sectionTitle('Consumidores conectados', Icons.power),
              _buildConsumerList(dailyConsumption),
              const SizedBox(height: 24),
              _sectionTitle('Añadir consumidor', Icons.add_circle_outline),
              _buildAddCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: kBlue, size: 20),
          const SizedBox(width: 8),
          Text(text,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _card({required Widget child, Color? border}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? Colors.white10),
      ),
      child: child,
    );
  }

  Widget _chip(Widget child, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: op(Colors.black, 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: op(color, 0.5)),
      ),
      child: child,
    );
  }

  Widget _buildDiagramCard({
    required bool isSelfSufficient,
    required double totalInput,
    required double dailySolar,
    required double dailyAlternator,
    required double dailyShore,
    required double dailyConsumption,
    required double totalBatteryWh,
    required double usableBatteryWh,
    required double soc,
  }) {
    final statusColor = isSelfSufficient ? kGreen : Colors.orangeAccent;
    return _card(
      border: op(kBlue, 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Esquema energético animado',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Flujos en tiempo real con fuentes configuradas',
                        style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: op(statusColor, 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isSelfSufficient
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: statusColor,
                        size: 14),
                    const SizedBox(width: 4),
                    Text(isSelfSufficient ? 'Autosuficiente' : 'Déficit',
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('BATERÍA ${batteryType.toUpperCase()}',
                  style: const TextStyle(
                      color: kBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: op(kAmber, 0.4)),
                ),
                child: Text('Entrada: +${totalInput.toInt()} Wh/día',
                    style: const TextStyle(
                        color: kAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // DIBUJO ANIMADO MEJORADO
          AspectRatio(
            aspectRatio: 400 / 340,
            child: Container(
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CamperVanPainter(
                          anim: _flow,
                          soc: soc,
                          solarOn: enableSolar && dailySolar > 0,
                          boosterOn: enableBooster && dailyAlternator > 0,
                          shoreOn: enableShore230 && dailyShore > 0,
                          solarW: solarPanels,
                          boosterA: boosterAlternator,
                          shoreW: shorePowerAmps * 12.0,
                          inputWh: totalInput,
                          usedWh: dailyConsumption,
                          usableWh: usableBatteryWh,
                        ),
                      ),
                    ),
                    if (enableSolar)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _chip(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wb_sunny,
                                  color: kAmber, size: 13),
                              const SizedBox(width: 4),
                              Text('${fmt(sunHours)} h sol',
                                  style: const TextStyle(
                                      color: kAmber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          kAmber,
                        ),
                      ),
                    if (enableShore230)
                      Positioned(
                        top: enableSolar ? 34 : 6,
                        left: 6,
                        child: _chip(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.power,
                                  color: kBlue, size: 13),
                              const SizedBox(width: 4),
                              Text('230V (${fmt(shoreHours)}h)',
                                  style: const TextStyle(
                                      color: kBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          kBlue,
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _chip(
                        Text(
                          enableSolar
                              ? 'PANELES ${solarPanels.toInt()} W\n+${dailySolar.toInt()} Wh/d'
                              : 'PANELES APAGADOS',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: enableSolar ? kAmber : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        kBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // RESUMEN RÁPIDO
          Row(
            children: [
              _metricBox('Batería', '${totalBatteryWh.toInt()} Wh', kGreen),
              const SizedBox(width: 6),
              _metricBox('Solar/día', enableSolar ? '+${dailySolar.toInt()} Wh' : '0 Wh', kAmber),
              const SizedBox(width: 6),
              _metricBox('Booster/día', enableBooster ? '+${dailyAlternator.toInt()} Wh' : '0 Wh', kBlue),
              const SizedBox(width: 6),
              _metricBox('230V/día', enableShore230 ? '+${dailyShore.toInt()} Wh' : '0 Wh', Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: op(color, 0.35)),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 10)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required double dailyConsumption,
    required double totalInput,
    required double autonomyDays,
    required double netBalance,
    required double coverage,
  }) {
    final barColor = coverage >= 1 ? kGreen : (coverage >= 0.7 ? kAmber : kRed);
    final autoColor =
        autonomyDays >= 2 ? kGreen : (autonomyDays >= 1 ? kAmber : kRed);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen de autonomía y balance',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              _bigStat('Consumo diario', '${dailyConsumption.toInt()} Wh',
                  Colors.white),
              _bigStat('Entrada diaria', '${totalInput.toInt()} Wh', Colors.white),
              _bigStat('Autonomía útil',
                  '${autonomyDays.toStringAsFixed(1)} días', autoColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cobertura de la energía generada',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${(coverage * 100).toInt()} %',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: coverage.clamp(0.0, 1.0).toDouble(),
            minHeight: 10,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: Colors.black26,
            color: barColor,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                    netBalance >= 0
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: netBalance >= 0 ? kGreen : Colors.orangeAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    netBalance >= 0
                        ? '¡Sistema autosuficiente! Sobran ${netBalance.toInt()} Wh/día'
                        : 'Déficit energético diario de ${netBalance.abs().toInt()} Wh',
                    style: TextStyle(
                        color: netBalance >= 0 ? kGreen : Colors.orangeAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tipo de batería',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButton<String>(
              value: batteryType,
              isExpanded: true,
              dropdownColor: kCard,
              underline: const SizedBox(),
              items: batteryEfficiencyMap.keys
                  .map((t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text(
                            '$t  ·  ${(batteryEfficiencyMap[t]! * 100).toInt()}% útil'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => batteryType = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          _slider(Icons.battery_charging_full, 'Capacidad batería', 'Ah',
              batteryCapacity, 50, 400, 5, (v) => setState(() => batteryCapacity = v)),
          
          const Divider(height: 24, color: Colors.white12),
          
          // --- PANELES SOLARES (Con Switch On/Off) ---
          Row(
            children: [
              const Icon(Icons.solar_power, color: kAmber, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('Paneles solares', style: TextStyle(fontWeight: FontWeight.bold))),
              Switch(
                value: enableSolar,
                activeColor: kAmber,
                onChanged: (val) => setState(() => enableSolar = val),
              ),
            ],
          ),
          if (enableSolar) ...[
            _slider(Icons.wb_sunny, 'Potencia paneles', 'W', solarPanels, 50, 1000, 25, (v) => setState(() => solarPanels = v)),
            _slider(Icons.access_time, 'Horas de sol pico', 'h/día', sunHours, 1, 8, 0.5, (v) => setState(() => sunHours = v)),
          ],

          const Divider(height: 24, color: Colors.white12),

          // --- BOOSTER ALTERNADOR (Con Switch On/Off) ---
          Row(
            children: [
              const Icon(Icons.bolt, color: kBlue, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('Booster alternador', style: TextStyle(fontWeight: FontWeight.bold))),
              Switch(
                value: enableBooster,
                activeColor: kBlue,
                onChanged: (val) => setState(() => enableBooster = val),
              ),
            ],
          ),
          if (enableBooster) ...[
            _slider(Icons.electric_car, 'Intensidad booster', 'A', boosterAlternator, 0, 100, 5, (v) => setState(() => boosterAlternator = v)),
            _slider(Icons.timer, 'Horas de conducción', 'h/día', drivingHours, 0, 6, 0.5, (v) => setState(() => drivingHours = v)),
          ],

          const Divider(height: 24, color: Colors.white12),

          // --- TOMA EXTERIOR 230V (Con Switch On/Off) ---
          Row(
            children: [
              const Icon(Icons.power, color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('Toma exterior 230V (Camping)', style: TextStyle(fontWeight: FontWeight.bold))),
              Switch(
                value: enableShore230,
                activeColor: Colors.purpleAccent,
                onChanged: (val) => setState(() => enableShore230 = val),
              ),
            ],
          ),
          if (enableShore230) ...[
            _slider(Icons.ev_station, 'Cargador 230V', 'A (12V)', shorePowerAmps, 5, 50, 5, (v) => setState(() => shorePowerAmps = v)),
            _slider(Icons.timer_outlined, 'Horas conectado a 230V', 'h/día', shoreHours, 0, 24, 1, (v) => setState(() => shoreHours = v)),
          ],
        ],
      ),
    );
  }

  Widget _slider(IconData icon, String label, String unit, double value,
      double min, double max, double step, ValueChanged<double> onChanged) {
    var divisions = ((max - min) / step).round();
    if (divisions <= 0) divisions = 1;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              Text('${fmt(value)} $unit',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: kBlue)),
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
      ),
    );
  }

  Widget _buildConsumerList(double total) {
    if (consumers.isEmpty) {
      return _card(
        child: const Text('No hay consumidores. Añade el primero abajo.',
            style: TextStyle(color: Colors.white60)),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < consumers.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _editConsumer(i),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(consumers[i].name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              '${fmt(consumers[i].power)} W · ${fmt(consumers[i].hours)} h/día',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text('${consumers[i].wh.toInt()} Wh',
                        style: const TextStyle(
                            color: kRed, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: Colors.white54,
                      onPressed: () => _editConsumer(i),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: kRed,
                      onPressed: () =>
                          setState(() => consumers.removeAt(i)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: LinearProgressIndicator(
                    value: total > 0 ? consumers[i].wh / total : 0,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: Colors.white10,
                    color: op(kRed, 0.8),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aparatos frecuentes',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: [
              for (final p in presets)
                ActionChip(
                  label: Text(p.name, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _nameController.text = p.name;
                    _powerController.text = fmt(p.power);
                    _hoursController.text = fmt(p.hours);
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre del aparato'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _powerController,
                  keyboardType: numKeyboard,
                  decoration: const InputDecoration(labelText: 'Potencia (W)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _hoursController,
                  keyboardType: numKeyboard,
                  decoration: const InputDecoration(labelText: 'Horas al día'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addConsumer,
              icon: const Icon(Icons.add),
              label: const Text('Añadir a la lista'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DIBUJO ANIMADO: autocaravana, sol dinámico, panel, 230V y flujos
// ---------------------------------------------------------------------------
class CamperVanPainter extends CustomPainter {
  final Animation<double> anim;
  final double soc;
  final bool solarOn;
  final bool boosterOn;
  final bool shoreOn;
  final double solarW;
  final double boosterA;
  final double shoreW;
  final double inputWh;
  final double usedWh;
  final double usableWh;

  CamperVanPainter({
    required this.anim,
    required this.soc,
    required this.solarOn,
    required this.boosterOn,
    required this.shoreOn,
    required this.solarW,
    required this.boosterA,
    required this.shoreW,
    required this.inputWh,
    required this.usedWh,
    required this.usableWh,
  }) : super(repaint: anim);

  static const double w = 400;
  static const double h = 340;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / w, size.height / h);

    _drawSun(canvas);
    _drawPanel(canvas);
    _drawShoreSocket(canvas);
    _drawVan(canvas);
    _drawBattery(canvas);
    _drawFlows(canvas);

    canvas.restore();
  }

  // ---------------- SOL ----------------
  void _drawSun(Canvas canvas) {
    const c = Offset(48, 62);
    if (!solarOn) return;

    final beam = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(215, 50)
      ..lineTo(200, 84)
      ..close();
    canvas.drawPath(beam, Paint()..color = op(kAmber, 0.10));

    canvas.drawCircle(
      c,
      36,
      Paint()
        ..shader = RadialGradient(
          colors: [op(kAmber, 0.55), op(kAmber, 0.0)],
        ).createShader(Rect.fromCircle(center: c, radius: 36)),
    );
    canvas.drawCircle(c, 15, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawCircle(c, 11, Paint()..color = kAmber);

    final ray = Paint()
      ..color = kAmber
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 10; i++) {
      final a = i * math.pi / 5;
      canvas.drawLine(
        Offset(c.dx + 20 * math.cos(a), c.dy + 20 * math.sin(a)),
        Offset(c.dx + 27 * math.cos(a), c.dy + 27 * math.sin(a)),
        ray,
      );
    }
  }

  // ---------------- TOMA 230V EXTERNA ----------------
  void _drawShoreSocket(Canvas canvas) {
    if (!shoreOn) return;
    const pos = Offset(360, 185);

    // Enchufe / toma lateral azul parpadeante o activa
    canvas.drawCircle(pos, 12, Paint()..color = op(kBlue, 0.2));
    canvas.drawCircle(pos, 8, Paint()..color = kBlue);
    _text(canvas, '230V', Offset(pos.dx, pos.dy - 16), 8, kBlue);
  }

  // ---------------- PANEL SOLAR ----------------
  void _drawPanel(Canvas canvas) {
    const tl = Offset(215, 50);
    const tr = Offset(315, 50);
    const br = Offset(300, 84);
    const bl = Offset(200, 84);

    final leg = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(225, 84), const Offset(225, 94), leg);
    canvas.drawLine(const Offset(285, 84), const Offset(285, 94), leg);

    final path = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: solarOn ? [const Color(0xFF2A5C8F), const Color(0xFF0B1B33)] : [Colors.grey.shade800, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTRB(200, 50, 315, 84)),
    );

    if (solarOn) {
      final grid = Paint()
        ..color = op(Colors.white, 0.35)
        ..strokeWidth = 0.8;
      for (int i = 1; i < 7; i++) {
        final t = i / 7;
        canvas.drawLine(Offset.lerp(tl, tr, t)!, Offset.lerp(bl, br, t)!, grid);
      }
      canvas.drawLine(Offset.lerp(tl, bl, 0.5)!, Offset.lerp(tr, br, 0.5)!, grid);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = solarOn ? const Color(0xFFE2E8F0) : Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(257, 67), width: 54, height: 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(pill, Paint()..color = op(Colors.black, 0.6));
    _text(canvas, solarOn ? '${solarW.toInt()} W' : 'OFF', const Offset(257, 67), 11, solarOn ? kAmber : Colors.white38);
  }

  // ---------------- AUTOCARAVANA ----------------
  void _drawVan(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(200, 237), width: 310, height: 8),
      Paint()..color = op(Colors.black, 0.4),
    );

    canvas.save();
    canvas.translate(58, 92);
    canvas.scale(0.6);

    const white = Color(0xFFF8FAFC);
    const edge = Color(0xFFCBD5E1);
    const dark = Color(0xFF1E293B);

    final fill = Paint()..color = white;
    final edgeLine = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final bulge = RRect.fromRectAndRadius(
        const Rect.fromLTWH(430, 92, 40, 82), const Radius.circular(14));
    canvas.drawRRect(bulge, fill);
    canvas.drawRRect(bulge, edgeLine);

    final van = Path()
      ..moveTo(445, 214)
      ..lineTo(445, 28)
      ..quadraticBezierTo(445, 3, 420, 3)
      ..lineTo(95, 3)
      ..cubicTo(62, 3, 48, 20, 48, 44)
      ..lineTo(48, 58)
      ..quadraticBezierTo(48, 68, 60, 68)
      ..lineTo(118, 68)
      ..lineTo(34, 148)
      ..quadraticBezierTo(4, 152, 2, 176)
      ..lineTo(2, 196)
      ..quadraticBezierTo(2, 214, 22, 214)
      ..close();
    canvas.drawPath(van, fill);
    canvas.drawPath(van, edgeLine);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 194, 38, 16), const Radius.circular(6)),
      Paint()..color = const Color(0xFF94A3B8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 160, 18, 10), const Radius.circular(4)),
      Paint()..color = kAmber,
    );

    canvas.drawLine(const Offset(180, 33), const Offset(435, 33),
        Paint()
          ..color = edge
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);

    final glass = Paint()..color = dark;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(98, 18, 68, 28), const Radius.circular(14)),
      glass,
    );

    final cabWin = Path()
      ..moveTo(118, 82)
      ..lineTo(165, 82)
      ..lineTo(165, 138)
      ..lineTo(70, 138)
      ..close();
    canvas.drawPath(cabWin, Paint()..color = dark);
    canvas.drawPath(
      cabWin,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawLine(const Offset(172, 72), const Offset(172, 205), edgeLine);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(150, 150, 14, 5), const Radius.circular(2)),
      Paint()..color = const Color(0xFF94A3B8),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(198, 58, 94, 50), const Radius.circular(10)),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(366, 58, 56, 40), const Radius.circular(10)),
      glass,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(394, 128, 40, 70), const Radius.circular(8)),
      edgeLine,
    );

    // Booster DC-DC (solo si está activo)
    final booster = RRect.fromRectAndRadius(
        const Rect.fromLTWH(300, 112, 56, 40), const Radius.circular(8));
    canvas.drawRRect(booster, Paint()..color = boosterOn ? const Color(0xFFF59E0B) : Colors.grey.shade700);
    canvas.drawRRect(
      booster,
      Paint()
        ..color = boosterOn ? const Color(0xFFB45309) : Colors.grey.shade900
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (final cx in [70.0, 350.0]) {
      final c = Offset(cx, 210);
      canvas.drawCircle(c, 31, Paint()..color = kBg);
      canvas.drawCircle(c, 25, Paint()..color = white);
      canvas.drawCircle(c, 18, Paint()..color = dark);
      canvas.drawCircle(c, 10, Paint()..color = white);
      canvas.drawCircle(c, 3.5, Paint()..color = dark);
    }

    canvas.restore();

    _text(canvas, 'BOOSTER', const Offset(255, 166), 6.5, boosterOn ? const Color(0xFF1F2937) : Colors.white38);
    _text(canvas, boosterOn ? '${boosterA.toInt()} A' : 'OFF', const Offset(255, 177), 9,
        boosterOn ? const Color(0xFF1F2937) : Colors.white38);
  }

  // ---------------- BATERÍA ----------------
  void _drawBattery(Canvas canvas) {
    const x = 120.0, y = 262.0;
    final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(x, y, 130, 34), const Radius.circular(7));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF0B1220));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(x + 130, y + 9, 6, 16), const Radius.circular(2)),
      Paint()..color = const Color(0xFFE2E8F0),
    );

    final Color c = soc > 0.5
        ? const Color(0xFF10B981)
        : (soc > 0.25 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final filled = (soc * 4).ceil().clamp(0, 4);
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 8 + i * 29.5, y + 6, 25.5, 22),
            const Radius.circular(3)),
        Paint()..color = i < filled ? c : const Color(0xFF334155),
      );
    }

    _text(canvas, 'CARGA ${(soc * 100).round()} %', const Offset(185, 312), 11, c);
    _text(canvas, '${usableWh.toInt()} Wh útiles · al final del día',
        const Offset(185, 327), 8, Colors.white70);
  }

  // ---------------- FLUJOS ANIMADOS INTELIGENTES ----------------
  void _drawFlows(Canvas canvas) {
    // 1. Panel solar -> cargador (si está activo)
    _flowLine(
      canvas,
      const [Offset(255, 84), Offset(255, 158)],
      kGreen,
      solarOn,
    );

    // 2. Toma 230V externa -> batería (si está activa)
    if (shoreOn) {
      _flowLine(
        canvas,
        const [Offset(320, 185), Offset(240, 185), Offset(215, 258)],
        kBlue,
        true,
      );
    }

    // 3. Carga general hacia la batería
    _flowLine(
      canvas,
      const [Offset(255, 184), Offset(255, 192), Offset(215, 192), Offset(215, 258)],
      kGreen,
      solarOn || boosterOn || shoreOn,
    );

    // 4. Salida hacia consumos
    _flowLine(
      canvas,
      const [Offset(155, 260), Offset(155, 224)],
      kRed,
      true,
    );

    _text(canvas, '+${inputWh.toInt()} Wh/d', const Offset(264, 247), 8.5, kGreen);
    _text(canvas, '-${usedWh.toInt()} Wh/d', const Offset(112, 247), 8.5, kRed);
  }

  void _flowLine(Canvas canvas, List<Offset> pts, Color color, bool active) {
    final line = Paint()
      ..color = op(color, active ? 0.95 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);

    final a = pts[pts.length - 2];
    final b = pts.last;
    final ang = math.atan2(b.dy - a.dy, b.dx - a.dx);
    final head = Path()
      ..moveTo(b.dx - 7 * math.cos(ang - 0.5), b.dy - 7 * math.sin(ang - 0.5))
      ..lineTo(b.dx, b.dy)
      ..lineTo(b.dx - 7 * math.cos(ang + 0.5), b.dy - 7 * math.sin(ang + 0.5));
    canvas.drawPath(head, line);

    if (!active) return;

    double total = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      total += (pts[i + 1] - pts[i]).distance;
    }
    for (int k = 0; k < 3; k++) {
      double d = ((anim.value + k / 3) % 1.0) * total;
      for (int i = 0; i < pts.length - 1; i++) {
        final seg = (pts[i + 1] - pts[i]).distance;
        if (d <= seg) {
          final pos = Offset.lerp(pts[i], pts[i + 1], d / seg)!;
          canvas.drawCircle(pos, 5, Paint()..color = op(color, 0.35));
          canvas.drawCircle(pos, 2.8, Paint()..color = Colors.white);
          break;
        }
        d -= seg;
      }
    }
  }

  void _text(Canvas canvas, String t, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
            color: color, fontSize: size, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CamperVanPainter old) =>
      old.soc != soc ||
      old.solarOn != solarOn ||
      old.boosterOn != boosterOn ||
      old.shoreOn != shoreOn ||
      old.solarW != solarW ||
      old.boosterA != boosterA ||
      old.shoreW != shoreW ||
      old.inputWh != inputWh ||
      old.usedWh != usedWh ||
      old.usableWh != usableWh;
}
