import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sura_voxia/sura_voxia.dart';

class ModelsTestView extends StatefulWidget {
  const ModelsTestView({super.key});

  @override
  State<ModelsTestView> createState() => _ModelsTestViewState();
}

class _ModelsTestViewState extends State<ModelsTestView> {
  // Paleta de Colores SURA
  static const Color azulSura = Color(0xFF0033a0);
  static const Color aquaSura = Color(0xFF00aec7);
  static const Color azulVivo = Color(0xFF2d6df6);
  static const Color verdeExito = Color(0xFF067014);
  static const Color naranjaAlerta = Color(0xFFff8200);

  final TextEditingController _transcriptionController = TextEditingController(
    text: '''
Buenos días. Vamos a completar su ficha médica para entender mejor qué le sucede. Por favor, confírmeme su peso y estatura.

Claro, peso 82 kg y mido 1.75 metros. Me he sentido mal desde ayer, con fiebre. Me la tomé en casa y marcaba exactamente 38.7°C.

Entiendo. Voy a colocarle el oxímetro en el dedo. Marca una frecuencia cardíaca de 105 pulsaciones por minuto y una saturación de oxígeno del 96%. Su frecuencia respiratoria está algo elevada, cuento 22 respiraciones por minuto. Ahora permítame su brazo para la presión... marca 135 de sistólica y 85 de diastólica.

¿Es alérgico a algún medicamento o sustancia?

Sí, soy alérgico a la penicilina. La última vez que me la administraron se me cerró un poco la garganta y me salieron ronchas rojas con mucha picazón por todo el torso y los brazos; fue una reacción bastante fuerte en la piel. También me di cuenta hace poco que el polen y el polvo me hacen estornudar demasiado y me ponen los ojos llorosos, aunque eso es más estacional.

¿Toma algún medicamento actualmente o ha tenido cirugías?

No estoy tomando ningún medicamento actualmente, ni siquiera vitaminas. En cuanto a cirugías, solo una hernia inguinal cuando tenía como 5 años, pero nada de adulto ni ninguna condición crónica.

¿Siente dolor en este momento? Descríbame cómo es y, en una escala del 0 al 10, ¿qué tan fuerte lo siente?

Sí, tengo un dolor de cabeza constante, como si me apretaran las sienes, y un dolor muscular generalizado, sobre todo en la espalda y las piernas, como si estuviera molido. Siendo 0 nada de dolor y 10 el máximo dolor imaginable, lo ubico en un 6. Es un dolor sordo y persistente que me hace sentir muy débil, es bastante molesto para moverme.
''',
  );

  String _selectedModelPath = 'gpt-4.1-mini';
  bool _isProcessingLLM = false;
  String? _statusMessage;
  bool? _isSuccess;
  String? _llmResponse;

  @override
  void dispose() {
    _transcriptionController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE NEGOCIO ---

  Future<void> _generateLLMResponse() async {
    setState(() {
      _isProcessingLLM = true;
      _llmResponse = null;
      _statusMessage = null;
    });

    // Formulario de prueba: signos vitales
    const formJson = {
      'signosVitales': {
        'listaSignosVitales': [
          {"descripcion": "Presión Arterial Sistólica", "unidad": "mm Hg", "nombre": "PresionArterialSistolica", "minimo": 0.0, "maximo": 200.0, "campoId": 134, "tipoDato": null},
          {"descripcion": "Presión Arterial Diastólica", "unidad": "mm Hg", "nombre": "presionArterialDiastolica", "minimo": 0.0, "maximo": 180.0, "campoId": 135, "tipoDato": null},
          {"descripcion": "Frecuencia Cardiaca", "unidad": "Latidos/min", "nombre": "frecuenciaCardiaca", "minimo": 0.0, "maximo": 200.0, "campoId": 133, "tipoDato": null},
          {"descripcion": "Frecuencia Respiratoria", "unidad": "x min", "nombre": "frecuenciaRespiratoria", "minimo": 0.0, "maximo": 60.0, "campoId": 132, "tipoDato": null},
          {"descripcion": "Temperatura", "unidad": "°C", "nombre": "Temperatura", "minimo": 0.0, "maximo": 42.0, "campoId": 136, "tipoDato": null},
          {"descripcion": "Dolor", "unidad": null, "nombre": "Dolor", "minimo": 0.0, "maximo": 10.0, "campoId": 203, "tipoDato": null},
          {"descripcion": "Glucometría", "unidad": "mg/dl", "nombre": "glucometria", "minimo": 0.0, "maximo": 500.0, "campoId": 137, "tipoDato": null},
          {"descripcion": "Saturación de Oxígeno", "unidad": "%", "nombre": "saturacionOxigeno", "minimo": 0.0, "maximo": 100.0, "campoId": 8000030, "tipoDato": null},
        ],
      },
    };

    final result = await VoxiaFormController().processJson(
      formJson: formJson,
      transcription: _transcriptionController.text.trim(),
      modelFileName: _selectedModelPath,
    );

    // Construir el output tipado para mostrarlo bonito
    String responseText;
    if (result is VoxiaFormSuccess) {
      responseText = const JsonEncoder.withIndent('  ').convert(
        result.completedJson.toJson(),
      );
    } else {
      responseText = '';
    }

    setState(() {
      _isProcessingLLM = false;
      _isSuccess = result.isSuccess;
      if (result.isSuccess) {
        _llmResponse = responseText;
        _statusMessage = 'Análisis completado';
      } else {
        _statusMessage = result.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle("Selector de Modelo"),
                  const SizedBox(height: 12),
                  _buildModelSelector(),

                  const SizedBox(height: 32),
                  _buildSectionTitle("Entrada de Transcripción"),
                  const SizedBox(height: 12),
                  _buildTranscriptionInput(),

                  const SizedBox(height: 24),
                  if (_statusMessage != null) _buildStatusCard(),
                  if (_llmResponse != null) _buildResponseCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [azulSura, azulVivo],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.psychology, color: Colors.white, size: 32),
          SizedBox(width: 12),
          Text(
            'Models Test VoxIA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: azulSura,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildModelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedModelPath,
          isExpanded: true,
          items:
              [
                'gpt-4.1-mini',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value.split('/').last,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
          onChanged: (val) => setState(() => _selectedModelPath = val!),
        ),
      ),
    );
  }

  Widget _buildTranscriptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: _transcriptionController,
        maxLines: 10,
        decoration: InputDecoration(
          hintText: "Escribe la transcripción aquí...",
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isProcessingLLM
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: aquaSura,
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: azulVivo,
                      size: 30,
                    ),
                    onPressed: _generateLLMResponse,
                  ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final bool success = _isSuccess ?? false;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success
            ? verdeExito.withValues(alpha: 0.05)
            : naranjaAlerta.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: success
              ? verdeExito.withValues(alpha: 0.3)
              : naranjaAlerta.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.info,
            color: success ? verdeExito : naranjaAlerta,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: success ? verdeExito : naranjaAlerta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: azulSura.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: azulSura.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: azulVivo, size: 20),
              SizedBox(width: 8),
              Text(
                "Respuesta del LLM",
                style: TextStyle(color: azulSura, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            _llmResponse!,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
