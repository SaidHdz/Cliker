# **Instrucciones de Desarrollo (Godot 2D) para el Agente de IA**

## **Principios Fundamentales**

1. **Contexto del Proyecto:** Antes de proponer cualquier cambio, revisa siempre los documentos clave (README.md, planes de implementación) y, lo más importante, la **estructura de escenas y scripts existentes** en el proyecto. El contexto es esencial.  
2. **Desarrollo Incremental:** La metodología es estrictamente incremental. No intentes implementar sistemas completos (ej. "un inventario") en una sola interacción. El objetivo es avanzar con pasos pequeños, funcionales y verificables (ej. "crear la escena del item", "añadir el script de datos del item", "añadir un nodo Area2D para recogerlo").  
3. **Claridad y GDScript:** Las explicaciones deben ser claras. El código **GDScript** generado debe seguir las convenciones de estilo oficiales de Godot y estar bien documentado donde sea necesario.  
4. **Enfoque Basado en Nodos y Escenas:** El desarrollo en Godot se centra en **Nodos** y **Escenas** (.tscn). Los scripts (.gd) son una parte de la escena, no una entidad aislada. Tu enfoque debe ser "configurar la escena" primero, y "añadir comportamiento con script" después.

## **Flujo de Trabajo para Nuevas Funcionalidades**

1. **Análisis de la Tarea:** Cuando se te asigne una tarea (ej. "Implementar el movimiento del jugador"), tu primera acción es proponer un **plan de acción detallado** para esa tarea.  
   * Desglosa la tarea en pasos lógicos de Godot.  
   * Identifica las **Escenas** (.tscn) que necesitarán ser creadas o modificadas.  
   * Identifica los **Scripts** (.gd) que se crearán o modificarán.  
   * Identifica los **Nodos** clave a añadir (ej. CharacterBody2D, CollisionShape2D, Sprite2D).  
   * Identifica los **Assets** (imágenes, sonidos) que se necesitarán.  
   * Finaliza tu propuesta preguntando explícitamente si debe iniciar la implementación.  
2. **Generación de Escenas y Scripts Modulares:**  
   * Una vez confirmado el plan, procede con la implementación paso a paso, enfocándote en **una entidad a la vez** (ej. "la escena del jugador", "el script del enemigo").  
   * **Nunca modifiques un script completo de golpe.** Propón los cambios en bloques lógicos.  
   * **Ejemplo de flujo:**  
     1. **IA:** "Primero, creemos la escena Player.tscn. El nodo raíz será un CharacterBody2D llamado 'Player'." (Espera confirmación).  
     2. **IA:** "Ahora, añade un Sprite2D y un CollisionShape2D como hijos de 'Player'." (Espera confirmación).  
     3. **IA:** "Perfecto. Ahora, creemos y adjuntemos un nuevo script, player.gd, al nodo 'Player'." (Espera confirmación).  
     4. **IA:** "En player.gd, empecemos añadiendo las variables de movimiento (ej. SPEED, GRAVITY) y la función \_physics\_process básica para la gravedad." (Entrega el bloque de código).  
3. **Proceso de Validación Iterativo:**  
   * Después de entregar un bloque de código (una nueva función, variables, una configuración de escena), **detén la generación**.  
   * Espera la confirmación del usuario de que:  
     1. El script **no muestra errores** en el editor de Godot.  
     2. La escena **se puede ejecutar** (usando F6 o F5) sin *crashear*.  
     3. El cambio (ej. "el personaje ahora cae por la gravedad") **se verifica visualmente** en el juego.  
   * Solo después de esta validación, procede con el siguiente paso de tu plan (ej. "Ahora, implementaremos el movimiento horizontal").

## **Reglas de Estilo y Contenido**

1. **Respuestas Concisas:** Evita generar scripts de GDScript excesivamente largos en una sola respuesta. Es preferible dividir una implementación en varias partes (variables, \_ready, \_physics\_process, señales).  
2. **Cero Emojis en Archivos Técnicos:** No se deben usar emojis en el código fuente (.gd), comentarios de código, ni en documentos técnicos del proyecto.  
3. **Lenguaje:** Mantén la comunicación en español. Los comentarios en el código pueden estar en inglés o español, según la convención que establezcamos.  
4. **Prioriza Nodos Nativos:** Propón siempre el uso de los nodos y funciones nativas de Godot (ej. Area2D para *triggers*, Timer para esperas, AnimationPlayer para animaciones) antes de inventar lógica compleja personalizada.  
5. **Assets:** La importación y configuración de assets (imágenes, *tilemaps*, audio) se tratará como un paso de implementación separado y validable (ej. "Importa tu *sprite sheet* y configúralo en el nodo Sprite2D").

## **Objetivo de Estas Reglas**

* **Reducir Errores:** Asegurar que cada paso es validado en el editor de Godot minimiza la introducción de regresiones.  
* **Mantener un Desarrollo Ordenado:** Seguir un plan claro y progresivo facilita el seguimiento y la colaboración.  
* **Optimizar la Interacción:** Evitar respuestas largas y fallidas que requieran múltiples correcciones.  
* **Garantizar la Funcionalidad:** Cada bloque de código o cambio en la escena entregado debe ser, en la medida de lo posible, funcional y fácil de verificar.