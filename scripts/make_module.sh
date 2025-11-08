#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Uso: $0 <module_name> [--force]"
  echo "Ejemplo: $0 login"
  exit 1
fi

MODULE_RAW="$1"       # p. ej., login, user_profile, players_list
FORCE=0
if [ "$2" == "--force" ]; then FORCE=1; fi

# ───── Helpers de nombres ─────────────────────────────────────────────────────
# snake_case -> snake_case (normalizamos)
to_snake() {
  echo "$1" | sed -E 's/([a-z0-9])([A-Z])/\1_\L\2/g' | tr '-' '_' | tr '[:upper:]' '[:lower:]'
}
# snake_case -> PascalCase
to_pascal() {
  local s=$(to_snake "$1")
  IFS=_ read -ra PARTS <<< "$s"
  local out=""
  for p in "${PARTS[@]}"; do
    out+=$(tr '[:lower:]' '[:upper:]' <<< ${p:0:1})${p:1}
  done
  echo "$out"
}

NAME_SNAKE=$(to_snake "$MODULE_RAW")        # login
NAME_PASCAL=$(to_pascal "$MODULE_RAW")      # Login
DIR="lib/modules/$NAME_SNAKE"

CONTROLLER_PATH="$DIR/${NAME_SNAKE}_controller.dart"
VIEW_PATH="$DIR/${NAME_SNAKE}_view.dart"
BINDING_PATH="$DIR/${NAME_SNAKE}_binding.dart"
INDEX_PATH="$DIR/index.dart"

# ───── Crear carpeta ──────────────────────────────────────────────────────────
mkdir -p "$DIR"

write_file() {
  local path="$1"
  local content="$2"
  if [ -f "$path" ] && [ $FORCE -eq 0 ]; then
    echo "⚠️  $path ya existe (omite). Usa --force para sobrescribir."
  else
    echo "$content" > "$path"
    echo "✅ Creado: $path"
  fi
}

# ───── Templates ──────────────────────────────────────────────────────────────
CONTROLLER_CONTENT="import 'package:get/get.dart';
import '../../../core/network/api_repository.dart';

class ${NAME_PASCAL}Controller extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    // TODO: init logic
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;
      // TODO: consume repo
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
"

VIEW_CONTENT="import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '${NAME_SNAKE}_controller.dart';

class ${NAME_PASCAL}View extends GetView<${NAME_PASCAL}Controller> {
  const ${NAME_PASCAL}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${NAME_PASCAL}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.value != null) {
            return Center(
              child: Text(
                controller.error.value!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const Center(
            child: Text('TODO: ${NAME_PASCAL} content'),
          );
        }),
      ),
    );
  }
}
"

BINDING_CONTENT="import 'package:get/get.dart';
import '${NAME_SNAKE}_controller.dart';

class ${NAME_PASCAL}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<${NAME_PASCAL}Controller>(() => ${NAME_PASCAL}Controller());
  }
}
"

INDEX_CONTENT="// Exports for ${NAME_PASCAL} module
export '${NAME_SNAKE}_view.dart';
export '${NAME_SNAKE}_controller.dart';
export '${NAME_SNAKE}_binding.dart';
"

# ───── Escribir archivos ──────────────────────────────────────────────────────
write_file "$CONTROLLER_PATH" "$CONTROLLER_CONTENT"
write_file "$VIEW_PATH" "$VIEW_CONTENT"
write_file "$BINDING_PATH" "$BINDING_CONTENT"

# Export index (opcional)
write_file "$INDEX_PATH" "$INDEX_CONTENT"

echo "🎯 Módulo '${NAME_SNAKE}' generado en $DIR"
echo "👉 Recuerda registrar la ruta en AppPages (getPages) cuando lo uses."