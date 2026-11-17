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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const SolarCalculatorScreen(),
    );
  }
}

class Aparato {
  String nombre;
  double potenciaW;
  double horasDia;
  bool activo;
  bool usaInversor; // Si es 220V añade un 15% de pérdida por el inversor
  IconData icono;

  Aparato({
    required this.nombre,
    required this.potenciaW,
    required this.horasDia,
    this.activo = true,
    this.usaInversor = false,
    this.icono = Icons.electrical_services,
  });

  double get consumoRealW => usaInversor ? potenciaW * 1.15 : potenciaW;
  double get consumoDiarioWh => activo ? (consumoRealW * horasDia) : 0.0;
}

class SolarCalculatorScreen extends StatefulWidget {
  const SolarCalculatorScreen({super.key});

  @override
  State<SolarCalculatorScreen> createState() => _SolarCalculatorScreenState();
}

class _SolarCalculatorScreenState extends State<SolarCalculatorScreen> {
  // Configuración de Batería
  String tipoBateria = 'Litio LiFePO4'; // 'Litio LiFePO4' (85%) o 'AGM / Gel' (50%)
  int voltaje = 12;
  double capacidadAh = 200;

  // Configuración Solar y Clima
  double potenciaPlacasW = 400;
  double horasSolPico = 4.0; // 2.0 Nublado, 4.0 Mixto, 5.5 Soleado
  final double eficienciaSolar = 0.80;

  // Configuración Booster DC-DC 12/12
  bool boosterActivo = true;
  double amperiosBooster = 30;
  double horasConduccion = 1.5;

  // Listado de aparatos
  final List<Aparato> aparatos = [
    Aparato(
      nombre: 'Nevera compresor 12V',
      potenciaW: 45,
      horasDia: 12,
      activo: true,
      usaInversor: false,
      icono: Icons.ac_unit,
    ),
    Aparato(
      nombre: 'Iluminación LED',
      potenciaW: 15,
      horasDia: 4,
      activo: true,
      usaInversor: false,
      icono: Icons.lightbulb,
    ),
    Aparato(
      nombre: 'Bomba de agua',
      potenciaW: 40,
      horasDia: 0.5,
      activo: true,
      usaInversor: false,
      icono: Icons.water_drop,
    ),
    Aparato(
      nombre: 'Portátil / TV (Inversor)',
      potenciaW: 65,
      horasDia: 2,
      activo: true,
      usaInversor: true,
      icono: Icons.tv,
    ),
  ];

  // Preajustes rápidos camper
  final List> preajustes = [
    {'nombre': 'Calefacción estacionaria', 'w': 25.0, 'h': 8.0, 'inv': false, 'icon': Icons.local_fire_department},
    {'nombre': 'Router WiFi / Starlink', 'w': 35.0, 'h': 10.0, 'inv': false, 'icon': Icons.wifi},
    {'nombre': 'Cafetera cápsulas (220V)', 'w': 1200.0, 'h': 0.15, 'inv': true, 'icon': Icons.coffee},
    {'nombre': 'Carga Bici Eléctrica', 'w': 150.0, 'h': 3.0, 'inv': true, 'icon': Icons.pedal_bike},
    {'nombre': 'Ventilador / Claraboya', 'w': 20.0, 'h': 6.0, 'inv': false, 'icon': Icons.air},
  ];

  // Cálculos energéticos
  double get dod => tipoBateria == 'Litio LiFePO4' ? 0.85 : 0.50;
  double get capacidadTotalWh => capacidadAh * voltaje;
  double get capacidadUtilWh => capacidadTotalWh * dod;

  double get produccionSolarWh => potenciaPlacasW * horasSolPico * eficienciaSolar;
  double get produccionBoosterWh => boosterActivo ? (amperiosBooster * voltaje * horasConduccion) : 0.0;
  double get generacionTotalWh => produccionSolarWh + produccionBoosterWh;

  double get consumoTotalWh {
    double total = 0;
    for (var a in aparatos) {
      total += a.consumoDiarioWh;
    }
    return total;
  }

  double get balanceNetoWh => generacionTotalWh - consumoTotalWh;

  String get textoAutonomia {
    if (consumoTotalWh <= 0) return '∞';
    if (balanceNetoWh >= 0) return 'Ilimitada';
    double deficitDiario = consumoTotalWh - generacionTotalWh;
    double dias = capacidadUtilWh / deficitDiario;
    if (dias >= 1) {
      return '${dias.toStringAsFixed(1)} días';
    } else {
      int horas = (dias * 24).round();
      return '$horas horas';
    }
  }

  void _abrirModalAgregarAparato() {
    final nombreCtrl = TextEditingController();
    final potenciaCtrl = TextEditingController();
    final horasCtrl = TextEditingController();
    bool usaInversor = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Añadir Consumo',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text('Preajustes rápidos:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: preajustes.map((p) {
                        return ActionChip(
                          avatar: Icon(p['icon'], size: 16),
                          label: Text(p['nombre'], style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            setModalState(() {
                              nombreCtrl.text = p['nombre'];
                              potenciaCtrl.text = p['w'].toString();
                              horasCtrl.text = p['h'].toString();
                              usaInversor = p['inv'];
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del aparato',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: potenciaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Potencia (W)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: horasCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Horas / día',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Usa Inversor 220V (+15% pérdida)'),
                      subtitle: const Text('Actívalo si se enchufa a corriente de casa'),
                      value: usaInversor,
                      onChanged: (val) => setModalState(() => usaInversor = val),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final w = double.tryParse(potenciaCtrl.text.replaceAll(',', '.')) ?? 0;
                          final h = double.tryParse(horasCtrl.text.replaceAll(',', '.')) ?? 0;
                          if (nombreCtrl.text.isNotEmpty && w > 0 && h > 0) {
                            setState(() {
                              aparatos.add(Aparato(
                                nombre: nombreCtrl.text,
                                potenciaW: w,
                                horasDia: h,
                                activo: true,
                                usaInversor: usaInversor,
                                icono: usaInversor ? Icons.power : Icons.electrical_services,
                              ));
                            });
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Guardar Aparato'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final esAutosuficiente = balanceNetoWh >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camper Solar Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ESQUEMA VISUAL DE LA AUTOCARAVANA
            _TarjetaEsquemaAutocaravana(
              produccionSolarWh: produccionSolarWh,
              produccionBoosterWh: produccionBoosterWh,
              consumoTotalWh: consumoTotalWh,
              capacidadUtilWh: capacidadUtilWh,
              tipoBateria: tipoBateria,
              capacidadAh: capacidadAh,
              voltaje: voltaje,
              boosterActivo: boosterActivo,
              horasSolPico: horasSolPico,
            ),
            const SizedBox(height: 16),

            // 2. RESUMEN DE AUTONOMÍA Y BALANCE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: esAutosuficiente
                      ? [Colors.teal.shade700, Colors.teal.shade500]
                      : [Colors.deepOrange.shade700, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AUTONOMÍA ESTIMADA',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        textoAutonomia,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        esAutosuficiente
                            ? 'Superávit diario: +${balanceNetoWh.toStringAsFixed(0)} Wh'
                            : 'Déficit diario: ${balanceNetoWh.toStringAsFixed(0)} Wh',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  Icon(
                    esAutosuficiente ? Icons.verified : Icons.battery_alert,
                    color: Colors.white,
                    size: 46,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. CONFIGURACIÓN DE BATERÍA
            const Text('1. Batería Auxiliar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Litio LiFePO4 (85%)')),
                            selected: tipoBateria == 'Litio LiFePO4',
                            onSelected: (_) => setState(() => tipoBateria = 'Litio LiFePO4'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('AGM / Gel (50%)')),
                            selected: tipoBateria == 'AGM / Gel',
                            onSelected: (_) => setState(() => tipoBateria = 'AGM / Gel'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Capacidad: ${capacidadAh.toInt()} Ah (${capacidadUtilWh.toInt()} Wh útiles)'),
                        DropdownButton<int>(
                          value: voltaje,
                          items: const [
                            DropdownMenuItem(value: 12, child: Text('12V')),
                            DropdownMenuItem(value: 24, child: Text('24V')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => voltaje = v);
                          },
                        ),
                      ],
                    ),
                    Slider(
                      value: capacidadAh,
                      min: 50,
                      max: 600,
                      divisions: 55,
                      label: '${capacidadAh.toInt()} Ah',
                      onChanged: (val) => setState(() => capacidadAh = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. PLACAS SOLARES Y CLIMA
            const Text('2. Placas Solares y Clima', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paneles: ${potenciaPlacasW.toInt()} W'),
                        Text(
                          '+${produccionSolarWh.toInt()} Wh/día',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    Slider(
                      value: potenciaPlacasW,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      label: '${potenciaPlacasW.toInt()} W',
                      onChanged: (val) => setState(() => potenciaPlacasW = val),
                    ),
                    const Text('Condiciones del día (Horas de Sol Pico):', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BotonClima(
                          icono: Icons.cloud,
                          texto: 'Nublado (2h)',
                          seleccionado: horasSolPico == 2.0,
                          onTap: () => setState(() => horasSolPico = 2.0),
                        ),
                        _BotonClima(
                          icono: Icons.wb_cloudy,
                          texto: 'Mixto (4h)',
                          seleccionado: horasSolPico == 4.0,
                          onTap: () => setState(() => horasSolPico = 4.0),
                        ),
                        _BotonClima(
                          icono: Icons.wb_sunny,
                          texto: 'Sol (5.5h)',
                          seleccionado: horasSolPico == 5.5,
                          onTap: () => setState(() => horasSolPico = 5.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. BOOSTER DC-DC 12/12
            const Text('3. Carga en Ruta (Booster DC-DC)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Booster 12/12 Activo', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(boosterActivo
                          ? 'Aporta +${produccionBoosterWh.toInt()} Wh conduciendo'
                          : 'Sin conducción hoy'),
                      value: boosterActivo,
                      onChanged: (val) => setState(() => boosterActivo = val),
                    ),
                    if (boosterActivo) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Corriente del Booster: ${amperiosBooster.toInt()} A'),
                          Text('${(amperiosBooster * voltaje).toInt()} W'),
                        ],
                      ),
                      Slider(
                        value: amperiosBooster,
                        min: 10,
                        max: 70,
                        divisions: 12,
                        label: '${amperiosBooster.toInt()} A',
                        onChanged: (val) => setState(() => amperiosBooster = val),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Conducción diaria: ${horasConduccion.toStringAsFixed(1)} horas'),
                        ],
                      ),
                      Slider(
                        value: horasConduccion,
                        min: 0.5,
                        max: 8.0,
                        divisions: 15,
                        label: '${horasConduccion.toStringAsFixed(1)} h',
                        onChanged: (val) => setState(() => horasConduccion = val),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. APARATOS Y CONSUMOS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '4. Consumos (${consumoTotalWh.toInt()} Wh/día)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                FilledButton.tonalIcon(
                  onPressed: _abrirModalAgregarAparato,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: aparatos.length,
              itemBuilder: (context, index) {
                final ap = aparatos[index];
                return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() => aparatos.removeAt(index));
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: ap.activo ? Colors.amber.shade100 : Colors.grey.shade200,
                        child: Icon(ap.icono, color: ap.activo ? Colors.amber.shade900 : Colors.grey),
                      ),
                      title: Row(
                        children: [
                          Flexible(child: Text(ap.nombre, overflow: TextOverflow.ellipsis)),
                          if (ap.usaInversor) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('220V', style: TextStyle(fontSize: 10, color: Colors.purple.shade800)),
                            ),
                          ]
                        ],
                      ),
                      subtitle: Text(
                        '${ap.potenciaW.toInt()}W × ${ap.horasDia}h = ${ap.consumoDiarioWh.toInt()} Wh/día',
                      ),
                      trailing: Switch(
                        value: ap.activo,
                        onChanged: (val) => setState(() => ap.activo = val),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalAgregarAparato,
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Aparato'),
      ),
    );
  }
}

class _BotonClima extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;

  const _BotonClima({
    required this.icono,
    required this.texto,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.amber.shade100 : Colors.grey.shade100,
          border: Border.all(color: seleccionado ? Colors.amber.shade800 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icono, size: 20, color: seleccionado ? Colors.amber.shade900 : Colors.grey.shade700),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TextStyle(
                fontSize: 11,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                color: seleccionado ? Colors.amber.shade900 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaEsquemaAutocaravana extends StatelessWidget {
  final double produccionSolarWh;
  final double produccionBoosterWh;
  final double consumoTotalWh;
  final double capacidadUtilWh;
  final String tipoBateria;
  final double capacidadAh;
  final int voltaje;
  final bool boosterActivo;
  final double horasSolPico;

  const _TarjetaEsquemaAutocaravana({
    required this.produccionSolarWh,
    required this.produccionBoosterWh,
    required this.consumoTotalWh,
    required this.capacidadUtilWh,
    required this.tipoBateria,
    required this.capacidadAh,
    required this.voltaje,
    required this.boosterActivo,
    required this.horasSolPico,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FLUJO ENERGÉTICO CAMPER',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Icon(
                horasSolPico >= 5 ? Icons.wb_sunny : (horasSolPico >= 3 ? Icons.wb_cloudy : Icons.cloud),
                color: Colors.amber,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Panel Solar
              _NodoFlujo(
                icono: Icons.solar_power,
                color: Colors.greenAccent,
                titulo: 'Placa Solar',
                valor: '+${produccionSolarWh.toInt()} Wh',
              ),
              const Icon(Icons.arrow_forward, color: Colors.white38, size: 18),
              // Batería Central
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.battery_charging_full, color: Colors.amber, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      '${capacidadAh.toInt()}Ah ${voltaje}V',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      '${capacidadUtilWh.toInt()} Wh útiles',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white38, size: 18),
              // Consumos
              _NodoFlujo(
                icono: Icons.rv_hookup,
                color: Colors.redAccent,
                titulo: 'Consumo',
                valor: '-${consumoTotalWh.toInt()} Wh',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: boosterActivo ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car,
                  size: 16,
                  color: boosterActivo ? Colors.lightBlueAccent : Colors.white38,
                ),
                const SizedBox(width: 6),
                Text(
                  boosterActivo
                      ? 'Alternador + Booster DC-DC: +${produccionBoosterWh.toInt()} Wh/día'
                      : 'Motor apagado (Booster en reposo)',
                  style: TextStyle(
                    color: boosterActivo ? Colors.lightBlueAccent : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NodoFlujo extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String valor;

  const _NodoFlujo({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: color, size: 24),
        const SizedBox(height: 4),
        Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(valor, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
