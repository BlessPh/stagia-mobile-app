import 'package:flutter/foundation.dart';

/// Signale aux écrans déjà montés qu'une étape du workflow de stage a changé.
abstract final class SuiviStageService {
  static final ValueNotifier<int> changements = ValueNotifier<int>(0);
  static final ValueNotifier<int?> ongletStagesDemande = ValueNotifier<int?>(
    null,
  );

  static void notifierChangement() {
    changements.value++;
  }

  static void ouvrirOngletStages(int index) {
    ongletStagesDemande.value = index;
  }
}
