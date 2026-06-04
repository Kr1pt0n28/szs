# 🎯 Flujo Completo del Cuestionario por Voz

## Diagrama de Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        VoxiaQuestionnaireManager                            │
│                         (ChangeNotifier - UI)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  Estado Público                    │  Estado Privado                        │
│  ─────────────────                 │  ───────────────                       │
│  VoxiaQuestionnaireState           │  _sessionActive                        │
│    ├─ voiceState                   │  _sessionCompleted                     │
│    ├─ messages[]                   │  _pendingVoiceStart                    │
│    ├─ summary                      │  _awaitingAnswer                       │
│    ├─ sessionActive                │  _processingAnswer                     │
│    ├─ sessionCompleted             │  _lastProcessedTranscript              │
│    └─ lastError                    │  _lastError                            │
├────────────────────────────────────┴────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐    ┌──────────────────────────────────────────┐   │
│  │   VoxiaController   │◄───│  _QuestionnaireFlowController            │   │
│  │   (Voz)             │    │  (Lógica de navegación y validación)     │   │
│  │   ├─ speakText()    │    │  ├─ currentPrompt                        │   │
│  │   ├─ startListen()  │    │  ├─ validateCurrentAnswer()              │   │
│  │   ├─ stopListen()   │    │  ├─ recordAnswer()                       │   │
│  │   └─ state          │    │  ├─ advanceAndGetPrompt()                │   │
│  └─────────────────────┘    │  └─ buildSummary()                       │   │
│                             └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Flujo Principal: Inicio de Sesión

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INICIO DE SESIÓN                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │       startSession()          │
                    │   (Usuario presiona botón)    │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ _ensureQuestionnaireLoaded()  │
                    │   ¿JSON cargado?              │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               │               ▼
              ┌──────────┐         │         ┌──────────┐
              │   ❌ No  │         │         │   ✅ Sí  │
              │  Error   │         │         │  Listo   │
              └────┬─────┘         │         └────┬─────┘
                   │               │              │
                   ▼               │              ▼
           ┌────────────┐          │    ┌─────────────────────┐
           │ _lastError │          │    │ ¿Voz ya conectada?  │
           │ _emitState │          │    │ status == ready?    │
           │   return   │          │    └──────────┬──────────┘
           └────────────┘          │               │
                                   │    ┌──────────┼──────────┐
                                   │    │          │          │
                                   │    ▼          │          ▼
                                   │ ┌──────┐      │      ┌──────┐
                                   │ │  Sí  │      │      │  No  │
                                   │ └──┬───┘      │      └──┬───┘
                                   │    │          │         │
                                   │    ▼          │         ▼
                                   │ ┌─────────────────────────────┐
                                   │ │ _startQuestionnaireConvers..│
                                   │ │ (directo, voz ya lista)     │
                                   │ └─────────────────────────────┘
                                   │               │
                                   │               ▼
                                   │    ┌──────────────────────┐
                                   │    │ _pendingVoiceStart   │
                                   │    │ = true               │
                                   │    │ _voiceController     │
                                   │    │   .login()           │
                                   │    └──────────┬───────────┘
                                   │               │
                                   │               ▼
                                   │    ┌──────────────────────┐
                                   │    │ _handleVoiceState    │
                                   │    │ Update() detecta:    │
                                   │    │ status == ready      │
                                   │    └──────────┬───────────┘
                                   │               │
                                   │               ▼
                                   └──────►┌────────────────────────────┐
                                           │ _startQuestionnaire        │
                                           │ Conversation()             │
                                           └────────────────────────────┘
```

---

## 💬 Flujo de Conversación: Pregunta-Respuesta

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      INICIO DE CONVERSACIÓN                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ _startQuestionnaireConvers..()│
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
        ┌────────────────────┐          ┌─────────────────────────┐
        │ Agregar mensaje:   │          │ 🔊 TTS: "Hola, soy      │
        │ "Hola, soy Voxia.."│          │ Voxia, tu asistente..." │
        │ _emitState()       │          │ await speakText()       │
        └────────────────────┘          └────────────┬────────────┘
                                                     │
                                                     ▼
                                        ┌────────────────────────┐
                                        │ _askCurrentQuestion()  │
                                        └────────────┬───────────┘
                                                     │
                    ┌────────────────────────────────┼────────────────────────┐
                    │                                │                        │
                    ▼                                ▼                        ▼
          ┌──────────────┐               ┌────────────────┐        ┌─────────────────┐
          │ flow == null │               │ prompt == null │        │ prompt != null  │
          │    ❌        │               │ (no más preg.) │        │ Hay pregunta    │
          └──────┬───────┘               └───────┬────────┘        └────────┬────────┘
                 │                               │                          │
                 ▼                               ▼                          ▼
          ┌────────────┐             ┌───────────────────────┐   ┌───────────────────┐
          │ Error      │             │ _finishQuestionnaire()│   │_askSpecificQuestion│
          │ return     │             │ (finalizar)           │   │    (prompt)       │
          └────────────┘             └───────────────────────┘   └───────────────────┘
```

---

## 🎤 Flujo de Pregunta Específica

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      _askSpecificQuestion(prompt)                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           │
┌───────────────────┐   ┌────────────────────────┐              │
│ Agregar mensaje:  │   │ clearRecognizedText()  │              │
│ prompt al chat    │   │ (limpiar buffer #1)    │              │
│ _emitState()      │   └────────────┬───────────┘              │
└───────────────────┘                │                          │
                                     ▼                          │
                        ┌────────────────────────┐              │
                        │ 🔊 TTS: speakText()    │              │
                        │ (dice la pregunta)     │              │
                        │ await...               │              │
                        └────────────┬───────────┘              │
                                     │                          │
                                     ▼                          │
                        ┌────────────────────────┐              │
                        │ ¿Sesión sigue activa?  │              │
                        │ _sessionActive?        │              │
                        └────────────┬───────────┘              │
                                     │                          │
                    ┌────────────────┼────────────────┐         │
                    │                │                │         │
                    ▼                │                ▼         │
             ┌───────────┐           │         ┌───────────┐    │
             │    No     │           │         │    Sí     │    │
             │ (cerrada) │           │         │ (activa)  │    │
             └─────┬─────┘           │         └─────┬─────┘    │
                   │                 │               │          │
                   ▼                 │               ▼          │
            ┌────────────┐           │  ┌────────────────────┐  │
            │ Limpiar    │           │  │ clearRecognized    │  │
            │ banderas   │           │  │ Text() (buffer #2) │  │
            │ return     │           │  └─────────┬──────────┘  │
            └────────────┘           │            │             │
                                     │            ▼             │
                                     │  ┌────────────────────┐  │
                                     │  │ 🎤 startListening()│  │
                                     │  │ (activar micrófono)│  │
                                     │  └─────────┬──────────┘  │
                                     │            │             │
                                     │            ▼             │
                                     │  ┌────────────────────┐  │
                                     │  │ _awaitingAnswer    │  │
                                     │  │    = true          │  │
                                     │  │ _processingAnswer  │  │
                                     │  │    = false         │  │
                                     │  │ _emitState()       │  │
                                     │  └─────────┬──────────┘  │
                                     │            │             │
                                     │            ▼             │
                                     │  ┌────────────────────┐  │
                                     │  │ 🔄 ESPERANDO       │  │
                                     │  │ (función termina)  │  │
                                     │  │ (listener activo)  │  │
                                     │  └────────────────────┘  │
                                     │                          │
                                     └──────────────────────────┘
```

---

## 👂 Flujo de Detección de Respuesta (Event-Driven)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       _handleVoiceStateUpdate()                             │
│                    (Se ejecuta automáticamente)                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               │
        ┌───────────────────────┐                   │
        │ ¿Login pendiente Y    │                   │
        │  status == ready?     │                   │
        └───────────┬───────────┘                   │
                    │                               │
          ┌─────────┼─────────┐                     │
          │         │         │                     │
          ▼         │         ▼                     │
     ┌────────┐     │    ┌────────┐                 │
     │   Sí   │     │    │   No   │                 │
     └────┬───┘     │    └────┬───┘                 │
          │         │         │                     │
          ▼         │         ▼                     │
┌───────────────────┐│  ┌─────────────────────────┐ │
│ _pendingVoice     ││  │ ¿Sesión activa Y        │ │
│ Start = false     ││  │  awaitingAnswer Y       │ │
│ _sessionActive    ││  │  !processingAnswer Y    │ │
│ = true            ││  │  !isListening Y         │ │
│ _startQuestConv() ││  │  hasSpoken?             │ │
│ return            ││  └───────────┬─────────────┘ │
└───────────────────┘│              │               │
                     │    ┌─────────┼─────────┐     │
                     │    │         │         │     │
                     │    ▼         │         ▼     │
                     │┌────────┐    │    ┌────────┐ │
                     ││   Sí   │    │    │   No   │ │
                     │└────┬───┘    │    └────┬───┘ │
                     │     │        │         │     │
                     │     ▼        │         ▼     │
                     │┌─────────────────┐ ┌─────────────────┐
                     ││ transcript =    │ │ ¿Error nuevo?   │
                     ││ recognizedText  │ │ lastError !=    │
                     ││ .trim()         │ │ previous?       │
                     │└───────┬─────────┘ └────────┬────────┘
                     │        │                    │
                     │        ▼                    │
                     │┌─────────────────┐          │
                     ││ ¿transcript no  │          ▼
                     ││  vacío Y != last│    ┌──────────────┐
                     ││  Processed?     │    │ Agregar msg  │
                     │└───────┬─────────┘    │ error al chat│
                     │        │              └──────────────┘
                     │  ┌─────┼─────┐              │
                     │  │     │     │              │
                     │  ▼     │     ▼              │
                     │┌────┐  │  ┌────┐            │
                     ││ Sí │  │  │ No │            │
                     │└─┬──┘  │  └─┬──┘            │
                     │  │     │    │               │
                     │  ▼     │    │               │
                     │┌──────────────────┐         │
                     ││ _processingAnswer│         │
                     ││ = true           │         │
                     ││                  │         │
                     ││ _handleVoice     │         │
                     ││ Answer(transcript)         │
                     ││ return           │         │
                     │└──────────────────┘         │
                     │                             │
                     └─────────────────────────────┼──────────┐
                                                   │          │
                                                   ▼          │
                                           ┌────────────┐     │
                                           │ _emitState │ ◄───┘
                                           │ (siempre)  │
                                           └────────────┘
```

---

## ✅ Flujo de Procesamiento de Respuesta

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      _handleVoiceAnswer(transcript)                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ _awaitingAnswer = false       │
                    │ _lastProcessedTranscript      │
                    │   = transcript                │
                    │ _emitState()                  │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ if (isListening)              │
                    │   stopListening()             │
                    │ clearRecognizedText()         │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ validation = flow             │
                    │   .validateCurrentAnswer()    │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               │               ▼
          ┌─────────────────┐       │     ┌─────────────────┐
          │ ❌ INVÁLIDA     │       │     │ ✅ VÁLIDA       │
          │ !validation     │       │     │ validation      │
          │ .isValid        │       │     │ .isValid        │
          └────────┬────────┘       │     └────────┬────────┘
                   │                │              │
                   ▼                │              ▼
          ┌─────────────────┐       │     ┌─────────────────┐
          │ Agregar msgs:   │       │     │ normalized =    │
          │ - patient(trans)│       │     │   validation    │
          │ - assistant     │       │     │   .normalizedVal│
          │   (errorMsg)    │       │     │                 │
          │ _emitState()    │       │     │ echo = valid    │
          └────────┬────────┘       │     │  .echoResponse  │
                   │                │     └────────┬────────┘
                   ▼                │              │
          ┌─────────────────┐       │              ▼
          │ 🔊 TTS:         │       │     ┌─────────────────┐
          │ speakText(error)│       │     │ Agregar msg:    │
          └────────┬────────┘       │     │ patient(echo)   │
                   │                │     │ _emitState()    │
                   ▼                │     └────────┬────────┘
          ┌─────────────────┐       │              │
          │ ¿Sesión activa? │       │              ▼
          └────────┬────────┘       │     ┌─────────────────┐
                   │                │     │ flow.record     │
          ┌────────┼────────┐       │     │ Answer(normal)  │
          │        │        │       │     └────────┬────────┘
          ▼        │        ▼       │              │
     ┌────────┐    │   ┌────────┐   │              ▼
     │   No   │    │   │   Sí   │   │     ┌─────────────────┐
     └────┬───┘    │   └────┬───┘   │     │ nextPrompt =    │
          │        │        │       │     │   flow.advance  │
          ▼        │        ▼       │     │   AndGetPrompt()│
     ┌────────┐    │   ┌────────────┐│    └────────┬────────┘
     │ return │    │   │ _askCurrent││             │
     └────────┘    │   │ Question() ││    ┌────────┼────────┐
                   │   │ (REPETIR)  ││    │        │        │
                   │   └────────────┘│    ▼        │        ▼
                   │                 │ ┌──────┐    │    ┌──────┐
                   │                 │ │ null │    │    │prompt│
                   │                 │ └──┬───┘    │    └──┬───┘
                   │                 │    │        │       │
                   │                 │    ▼        │       ▼
                   │                 │ ┌────────────────┐ ┌────────────────┐
                   │                 │ │_finishQuestion-│ │_askSpecific    │
                   │                 │ │naire()         │ │Question(next)  │
                   │                 │ │(TERMINAR)      │ │(SIGUIENTE)     │
                   │                 │ └────────────────┘ └────────────────┘
                   │                 │          │               │
                   └─────────────────┼──────────┴───────────────┘
                                     │
                                     ▼
                          ┌───────────────────┐
                          │ _processingAnswer │
                          │   = false         │
                          │ _emitState()      │
                          └───────────────────┘
```

---

## 🏁 Flujo de Finalización

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         _finishQuestionnaire()                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ if (isListening)              │
                    │   stopListening()             │
                    │ clearRecognizedText()         │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ _summary = flow.buildSummary()│
                    │                               │
                    │ Genera texto como:            │
                    │ ┌─────────────────────────┐   │
                    │ │ INFORMACIÓN PERSONAL    │   │
                    │ │ - Nombre: Juan Pérez    │   │
                    │ │ - Edad: 35              │   │
                    │ │                         │   │
                    │ │ SÍNTOMAS                │   │
                    │ │ - Fiebre: Sí, 3 días    │   │
                    │ │ - Dolor: 7.0            │   │
                    │ └─────────────────────────┘   │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ _sessionCompleted = true      │
                    │ _sessionActive = false        │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ Agregar mensaje:              │
                    │ "Listo, ya tengo todos los    │
                    │  datos necesarios. Gracias."  │
                    │ _emitState()                  │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ 🔊 TTS: speakText(despedida)  │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │      ✅ CUESTIONARIO          │
                    │         COMPLETADO            │
                    │                               │
                    │  state.sessionCompleted ==    │
                    │    true                       │
                    │  state.summary disponible     │
                    └───────────────────────────────┘
```

---

## 🔄 Ciclo Completo Resumido

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 CICLO PRINCIPAL                                        │
└────────────────────────────────────────────────────────────────────────────────────────┘


    ┌──────────────┐         ┌───────────────┐         ┌────────────────┐
    │ USUARIO      │         │   MANAGER     │         │ FLOW CONTROLLER│
    │ presiona     │────────►│ startSession()│────────►│ Carga JSON     │
    │ "Iniciar"    │         │               │         │ Inicializa     │
    └──────────────┘         └───────────────┘         └────────────────┘
                                    │
                                    ▼
                            ┌───────────────┐
                            │ Conectar voz  │
                            │ login()       │
                            └───────┬───────┘
                                    │
      ┌─────────────────────────────┘
      ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                                    LOOP PRINCIPAL                                     │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐ │
│  │                                                                                  │ │
│  │    ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌───────────┐ │ │
│  │    │ 🔊 Asistente│      │ 🎤 Micrófono│      │ 👂 Detectar │      │ ✅ Validar│ │ │
│  │    │ hace        │─────►│ escucha     │─────►│ respuesta   │─────►│ respuesta │ │ │
│  │    │ pregunta    │      │ usuario     │      │ (listener)  │      │           │ │ │
│  │    └─────────────┘      └─────────────┘      └─────────────┘      └─────┬─────┘ │ │
│  │          ▲                                                              │       │ │
│  │          │              ┌─────────────────────────────────────────────┐ │       │ │
│  │          │              │                                             │ │       │ │
│  │          │    ┌─────────┴──────────┐                    ┌─────────────┴─┴─────┐ │ │
│  │          │    │ ❌ INVÁLIDA        │                    │ ✅ VÁLIDA           │ │ │
│  │          │    │ Error + Repetir    │                    │ Guardar + Avanzar   │ │ │
│  │          │    └────────────────────┘                    └─────────────────────┘ │ │
│  │          │                                                        │             │ │
│  │          └────────────────────────────────────────────────────────┘             │ │
│  │                                                                                  │ │
│  └──────────────────────────────────────────────────────────────────────────────────┘ │
│                                         │                                             │
│                              ┌──────────┴──────────┐                                  │
│                              │ ¿Más preguntas?     │                                  │
│                              └──────────┬──────────┘                                  │
│                                         │                                             │
│                           ┌─────────────┼─────────────┐                               │
│                           │             │             │                               │
│                           ▼             │             ▼                               │
│                    ┌───────────┐        │      ┌───────────┐                          │
│                    │    SÍ     │        │      │    NO     │                          │
│                    │  (loop)   │        │      │ (salir)   │                          │
│                    └─────┬─────┘        │      └─────┬─────┘                          │
│                          │              │            │                                │
│                          └──────────────┤            │                                │
│                                         │            │                                │
└─────────────────────────────────────────┼────────────┼────────────────────────────────┘
                                          │            │
                                          │            ▼
                                          │   ┌────────────────┐
                                          │   │ _finishQuest() │
                                          │   │ Generar summary│
                                          │   │ Despedida      │
                                          │   └────────┬───────┘
                                          │            │
                                          │            ▼
                                          │   ┌────────────────┐
                                          │   │   COMPLETADO   │
                                          │   │   summary      │
                                          │   │   disponible   │
                                          │   └────────────────┘
                                          │
                                          └───────── (continúa loop si hay más)
```

---

## 📊 Estados de Banderas Durante el Flujo

| Estado | sessionActive | awaitingAnswer | processingAnswer | sessionCompleted |
|--------|:-------------:|:--------------:|:----------------:|:----------------:|
| Inicial | ❌ | ❌ | ❌ | ❌ |
| Login pendiente | ❌ | ❌ | ❌ | ❌ |
| Sesión iniciada | ✅ | ❌ | ❌ | ❌ |
| Pregunta hecha | ✅ | ✅ | ❌ | ❌ |
| Usuario respondiendo | ✅ | ✅ | ❌ | ❌ |
| Procesando respuesta | ✅ | ❌ | ✅ | ❌ |
| Siguiente pregunta | ✅ | ✅ | ❌ | ❌ |
| Cuestionario completado | ❌ | ❌ | ❌ | ✅ |

---

## 🔗 Dependencias entre Funciones

```
startSession()
    │
    ├──► _ensureQuestionnaireLoaded()
    │        └──► _loadQuestionnaireFromAsset()
    │                 └──► _initializeWithSections()
    │
    └──► [login() o directo]
              │
              └──► _startQuestionnaireConversation()
                        │
                        ├──► speakText() (bienvenida)
                        │
                        └──► _askCurrentQuestion()
                                  │
                                  ├──► _finishQuestionnaire() (si no hay más)
                                  │
                                  └──► _askSpecificQuestion()
                                            │
                                            ├──► speakText()
                                            ├──► startListening()
                                            │
                                            └──► [ESPERAR]
                                                      │
                                                      │
_handleVoiceStateUpdate() ◄───────────────────────────┘
    │                         (listener automático)
    │
    └──► _handleVoiceAnswer()
              │
              ├──► validateCurrentAnswer()
              │
              ├──► [INVÁLIDA] ──► _askCurrentQuestion() (repetir)
              │
              └──► [VÁLIDA]
                      │
                      ├──► recordAnswer()
                      ├──► advanceAndGetPrompt()
                      │
                      ├──► _askSpecificQuestion() (siguiente)
                      │
                      └──► _finishQuestionnaire() (si no hay más)
                                │
                                ├──► buildSummary()
                                └──► speakText() (despedida)
```

---

## 📝 Notas Clave

1. **Event-Driven**: El flujo no es lineal, `_handleVoiceStateUpdate()` reacciona a eventos del sistema de voz.

2. **Protección anti-duplicados**: `_lastProcessedTranscript` evita procesar la misma respuesta dos veces.

3. **Checkpoints de sesión**: `if (!_sessionActive)` aparece después de cada operación asíncrona para manejar cierre durante operaciones.

4. **Doble limpieza de buffer**: `clearRecognizedText()` se llama antes y después de TTS para evitar ecos.

5. **Inmutabilidad**: El estado público (`VoxiaQuestionnaireState`) es inmutable; solo se modifica internamente y se emite.
