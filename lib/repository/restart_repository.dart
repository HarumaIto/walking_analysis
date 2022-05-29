import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/home_providers.dart';
import '../state/log_provider.dart';

class RestartRepository {
  void restart(WidgetRef ref) {
    /* home page */
    ref.read(prepareStateProvider.notifier).state = true;
    ref.read(processStateProvider.notifier).state = false;
    ref.read(progressValProvider.notifier).reset();
    ref.read(dataListProvider.notifier).reset();
    ref.read(scoreProvider.notifier).state = '-----';

    /* log page */
    ref.read(inputThumbProvider.notifier).reset();
    ref.read(detectedThumbProvider.notifier).reset();
  }
}