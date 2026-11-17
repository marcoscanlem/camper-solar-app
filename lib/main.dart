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

/// Color con opacidad (compatible con cualquier versión de Flutter).
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
  // Configuración
  double batteryCapacity = 150.0; // Ah
  double solarPanels = 350.0; // W
  double sunHours = 4.0; // h sol pico
  double boosterAlternator = 30.0; // A
  double drivingHours = 1.5; // h/día

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

  // Aparatos frecuentes para añadir con un toque
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

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final usableDepth = batteryEfficiencyMap[batteryType] ?? 0.50;

    final dailyConsumption = consumers.fold<double>(0, (s, a) => s + a.wh);
    final dailySolar = solarPanels * sunHours;
    final dailyAlternator = boosterAlternator * drivingHours * 12.0;
    final totalInput = dailySolar + dailyAlternator;
    final netBalance = totalInput - dailyConsumption;
    final totalBatteryWh = batteryCapacity * 12.0;
    final usableBatteryWh = totalBatteryWh * usableDepth;
    final autonomyDays =
        dailyConsumption > 0 ? usableBatteryWh / dailyConsumption : 0.0;
    final isSelfSufficient = netBalance >= 0;
    final coverage = dailyConsumption > 0 ? totalInput / dailyConsumption : 1.0;

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
                dailyConsumption: dailyConsumption,
                totalBatteryWh: totalBatteryWh,
                coverage: coverage,
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

  // -------------------------------------------------------------------------
  // Widgets
  // -------------------------------------------------------------------------
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
    required double dailyConsumption,
    required double totalBatteryWh,
    required double coverage,
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
                    Text('Esquema energético',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Flujo de energía en tiempo real',
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

          // DIBUJO
          AspectRatio(
            aspectRatio: 400 / 290,
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
                          coverage: coverage,
                          solarOn: dailySolar > 0,
                          boosterOn: dailyAlternator > 0,
                        ),
                      ),
                    ),
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
                            Text('${fmt(sunHours)} h sol/día',
                                style: const TextStyle(
                                    color: kAmber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        kAmber,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _chip(
                        Text(
                          'PANELES ${solarPanels.toInt()} W\n+${dailySolar.toInt()} Wh/día',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: kAmber,
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
              _metricBox('Solar/día', '+${dailySolar.toInt()} Wh', kAmber),
              const SizedBox(width: 6),
              _metricBox(
                  'Booster/día', '+${dailyAlternator.toInt()} Wh', kBlue),
              const SizedBox(width: 6),
              _metricBox('Gasto/día', '-${dailyConsumption.toInt()} Wh', kRed),
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
          const SizedBox(height: 8),
          _slider(Icons.battery_charging_full, 'Capacidad batería', 'Ah',
              batteryCapacity, 50, 400, 5, (v) => setState(() => batteryCapacity = v)),
          _slider(Icons.solar_power, 'Paneles solares', 'W', solarPanels, 50,
              1000, 25, (v) => setState(() => solarPanels = v)),
          _slider(Icons.wb_sunny, 'Horas de sol pico', 'h/día', sunHours, 1, 8,
              0.5, (v) => setState(() => sunHours = v)),
          _slider(Icons.bolt, 'Booster alternador', 'A', boosterAlternator, 0,
              100, 5, (v) => setState(() => boosterAlternator = v)),
          _slider(Icons.directions_car, 'Horas de conducción', 'h/día',
              drivingHours, 0, 6, 0.5, (v) => setState(() => drivingHours = v)),
        ],
      ),
    );
  }

  Widget _slider(IconData icon, String label, String unit, double value,
      double min, double max, double step, ValueChanged<double> onChanged) {
    var divisions = ((max - min) / step).round();
    if (divisions <= 0) divisions = 1;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white70)),
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
// DIBUJO: autocaravana con capuchina, panel solar, booster y batería
// Coordenadas virtuales 400 x 290 (se escalan al tamaño disponible)
// ---------------------------------------------------------------------------
class CamperVanPainter extends CustomPainter {
  final Animation<double> anim;
  final double coverage; // entrada / consumo
  final bool solarOn;
  final bool boosterOn;

  CamperVanPainter({
    required this.anim,
    required this.coverage,
    required this.solarOn,
    required this.boosterOn,
  }) : super(repaint: anim);

  static const double w = 400;
  static const double h = 290;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / w, size.height / h);

    _drawSun(canvas);
    _drawPanel(canvas);
    _drawVan(canvas);
    _drawBooster(canvas);
    _drawBattery(canvas);
    _drawFlows(canvas);

    canvas.restore();
  }

  // ---------------- SOL ----------------
  void _drawSun(Canvas canvas) {
    const c = Offset(48, 66);

    // Haz de luz hacia el panel
    final beam = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(215, 58)
      ..lineTo(195, 92)
      ..close();
    canvas.drawPath(beam, Paint()..color = op(kAmber, 0.10));

    // Resplandor
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

    // Rayos
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

  // ---------------- PANEL SOLAR ----------------
  void _drawPanel(Canvas canvas) {
    const tl = Offset(215, 58);
    const tr = Offset(340, 58);
    const br = Offset(325, 92);
    const bl = Offset(195, 92);

    // Patas
    final leg = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(215, 92), const Offset(215, 101), leg);
    canvas.drawLine(const Offset(305, 92), const Offset(305, 101), leg);

    final path = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2A5C8F), Color(0xFF0B1B33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTRB(195, 58, 340, 92)),
    );

    final grid = Paint()
      ..color = op(Colors.white, 0.35)
      ..strokeWidth = 0.8;
    for (int i = 1; i < 7; i++) {
      final t = i / 7;
      canvas.drawLine(Offset.lerp(tl, tr, t)!, Offset.lerp(bl, br, t)!, grid);
    }
    canvas.drawLine(Offset.lerp(tl, bl, 0.5)!, Offset.lerp(tr, br, 0.5)!, grid);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

  }

  // ---------------- AUTOCARAVANA ----------------
  void _drawVan(Canvas canvas) {
    // Sombra en el suelo
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(194, 219), width: 350, height: 12),
      Paint()..color = op(Colors.black, 0.35),
    );

    // Escalerilla trasera
    final ladder = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(364, 112), const Offset(364, 186), ladder);
    canvas.drawLine(const Offset(371, 112), const Offset(371, 186), ladder);
    for (double y = 120; y <= 180; y += 12) {
      canvas.drawLine(Offset(364, y), Offset(371, y), ladder);
    }

    // Claraboya del techo
    final vent = RRect.fromRectAndRadius(
        const Rect.fromLTWH(132, 94, 28, 9), const Radius.circular(3));
    canvas.drawRRect(vent, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawRRect(
      vent,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Carrocería (capuchina delante a la izquierda)
    final van = Path()
      ..moveTo(360, 196)
      ..lineTo(360, 110)
      ..quadraticBezierTo(360, 102, 352, 102)
      ..lineTo(110, 102)
      ..quadraticBezierTo(60, 102, 52, 124) // frente de la capuchina
      ..quadraticBezierTo(48, 136, 56, 140)
      ..lineTo(112, 140) // bajo la capuchina
      ..lineTo(84, 168) // parabrisas
      ..lineTo(48, 178) // capó
      ..quadraticBezierTo(30, 182, 28, 194)
      ..lineTo(28, 196)
      ..close();

    canvas.drawPath(
      van,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFDDE5EE)],
        ).createShader(const Rect.fromLTRB(28, 100, 360, 196)),
    );

    // Zócalo y franja decorativa (recortados a la carrocería)
    canvas.save();
    canvas.clipPath(van);
    canvas.drawRect(const Rect.fromLTRB(28, 184, 360, 196),
        Paint()..color = const Color(0xFFCBD5E1));
    canvas.drawRect(const Rect.fromLTRB(166, 160, 360, 166), Paint()..color = kBlue);
    canvas.drawRect(const Rect.fromLTRB(166, 168, 360, 170),
        Paint()..color = op(kBlue, 0.5));
    canvas.restore();

    canvas.drawPath(
      van,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    // Línea de unión del techo
    canvas.drawLine(
      const Offset(118, 112),
      const Offset(352, 112),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 2,
    );

    final glass = Paint()..color = const Color(0xFF1E293B);
    final glassLine = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final panelLine = Paint()
      ..color = const Color(0xFFB6C2D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final handle = Paint()..color = const Color(0xFF64748B);

    // Ventana de la capuchina
    final overcab = RRect.fromRectAndRadius(
        const Rect.fromLTWH(66, 110, 46, 18), const Radius.circular(8));
    canvas.drawRRect(overcab, glass);
    canvas.drawRRect(overcab, glassLine);

    // Ventana de cabina (parabrisas + lateral)
    final cab = Path()
      ..moveTo(115, 146)
      ..lineTo(160, 146)
      ..lineTo(160, 168)
      ..lineTo(93, 168)
      ..close();
    canvas.drawPath(cab, glass);
    canvas.drawPath(cab, glassLine);
    // Reflejo del cristal
    canvas.drawLine(const Offset(130, 150), const Offset(122, 164),
        Paint()
          ..color = op(Colors.white, 0.18)
          ..strokeWidth = 3);

    // Puerta de cabina
    canvas.drawLine(const Offset(164, 142), const Offset(164, 188), panelLine);
    canvas.drawLine(const Offset(126, 188), const Offset(164, 188), panelLine);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(148, 175, 10, 3), const Radius.circular(1.5)),
      handle,
    );

    // Retrovisor
    canvas.drawLine(const Offset(94, 157), const Offset(103, 157), panelLine);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(86, 149, 8, 16), const Radius.circular(3)),
      Paint()..color = const Color(0xFF334155),
    );

    // Puerta de la vivienda
    final door = RRect.fromRectAndRadius(
        const Rect.fromLTWH(172, 114, 32, 72), const Radius.circular(4));
    canvas.drawRRect(door, panelLine);
    final doorWin = RRect.fromRectAndRadius(
        const Rect.fromLTWH(178, 120, 20, 26), const Radius.circular(4));
    canvas.drawRRect(doorWin, glass);
    canvas.drawRRect(doorWin, glassLine);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(194, 158, 6, 3), const Radius.circular(1.5)),
      handle,
    );

    // Ventanas laterales
    for (final r in const [
      Rect.fromLTWH(214, 120, 48, 30),
      Rect.fromLTWH(270, 120, 34, 30),
    ]) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
      canvas.drawRRect(rr, glass);
      canvas.drawRRect(rr, glassLine);
    }

    // Faro, parachoques delantero y trasero, piloto
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(31, 177, 12, 7), const Radius.circular(3)),
      Paint()..color = kAmber,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 187, 36, 10), const Radius.circular(4)),
      Paint()..color = const Color(0xFF64748B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(352, 186, 12, 10), const Radius.circular(3)),
      Paint()..color = const Color(0xFF64748B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(356, 140, 4, 18), const Radius.circular(2)),
      Paint()..color = const Color(0xFFEF4444),
    );

    // Pasos de rueda + ruedas
    for (final cx in [100.0, 290.0]) {
      final c = Offset(cx, 196);
      canvas.drawCircle(c, 24, Paint()..color = kBg);
      canvas.drawCircle(c, 19, Paint()..color = const Color(0xFF1F2937));
      canvas.drawCircle(
          c,
          19,
          Paint()
            ..color = const Color(0xFF64748B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
      canvas.drawCircle(c, 12, Paint()..color = const Color(0xFFE2E8F0));
      canvas.drawCircle(c, 8, Paint()..color = const Color(0xFF94A3B8));
      final spoke = Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 1.4;
      for (int i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5;
        canvas.drawLine(
          c,
          Offset(c.dx + 11 * math.cos(a), c.dy + 11 * math.sin(a)),
          spoke,
        );
      }
      canvas.drawCircle(c, 3.5, Paint()..color = const Color(0xFF334155));
    }
  }

  // ---------------- BOOSTER DC-DC ----------------
  void _drawBooster(Canvas canvas) {
    final r = RRect.fromRectAndRadius(
        const Rect.fromLTWH(308, 148, 42, 30), const Radius.circular(5));
    canvas.drawRRect(r, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawRRect(
      r,
      Paint()
        ..color = const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _text(canvas, 'BOOSTER', const Offset(329, 159), 6.5, const Color(0xFF1F2937));
    _text(canvas, 'DC-DC', const Offset(329, 169), 6, const Color(0xFF1F2937));
  }

  // ---------------- BATERÍA ----------------
  void _drawBattery(Canvas canvas) {
    const x = 150.0, y = 232.0;
    final body =
        RRect.fromRectAndRadius(const Rect.fromLTWH(x, y, 116, 30), const Radius.circular(6));
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
          const Rect.fromLTWH(x + 116, y + 8, 5, 14), const Radius.circular(2)),
      Paint()..color = const Color(0xFFE2E8F0),
    );

    // Celdas según la cobertura energética
    final filled = (coverage * 4).ceil().clamp(1, 4);
    for (int i = 0; i < 4; i++) {
      Color c;
      if (i >= filled) {
        c = const Color(0xFF334155);
      } else if (filled == 1) {
        c = const Color(0xFFEF4444);
      } else if (filled == 2) {
        c = const Color(0xFFF59E0B);
      } else {
        c = const Color(0xFF10B981);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 8 + i * 25.0, y + 6, 21, 18), const Radius.circular(2)),
        Paint()..color = c,
      );
    }
  }

  // ---------------- FLUJOS ANIMADOS ----------------
  void _drawFlows(Canvas canvas) {
    // Panel -> booster
    _flowLine(
      canvas,
      const [Offset(329, 92), Offset(329, 147)],
      kGreen,
      solarOn,
    );
    // Booster -> batería
    _flowLine(
      canvas,
      const [Offset(329, 178), Offset(329, 247), Offset(276, 247)],
      kGreen,
      solarOn || boosterOn,
    );
    // Batería -> consumos de la autocaravana
    _flowLine(
      canvas,
      const [Offset(208, 230), Offset(208, 198)],
      kRed,
      true,
    );
    _text(canvas, 'CONSUMO', const Offset(208, 277), 8, kRed);
    _text(canvas, 'CARGA', const Offset(305, 277), 8, kGreen);
  }

  void _flowLine(Canvas canvas, List<Offset> pts, Color color, bool active) {
    final line = Paint()
      ..color = op(color, active ? 0.95 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);

    // Punta de flecha
    final a = pts[pts.length - 2];
    final b = pts.last;
    final ang = math.atan2(b.dy - a.dy, b.dx - a.dx);
    final head = Path()
      ..moveTo(b.dx - 7 * math.cos(ang - 0.5), b.dy - 7 * math.sin(ang - 0.5))
      ..lineTo(b.dx, b.dy)
      ..lineTo(b.dx - 7 * math.cos(ang + 0.5), b.dy - 7 * math.sin(ang + 0.5));
    canvas.drawPath(head, line);

    if (!active) return;

    // Puntos que se desplazan por la línea
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
      old.coverage != coverage ||
      old.solarOn != solarOn ||
      old.boosterOn != boosterOn;
}
