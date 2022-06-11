import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/home_providers.dart';

class RestartRepository {

  RestartRepository.restart(WidgetRef ref) {
    /* home page */
    ref.read(prepareStateProvider.notifier).state = true;
    ref.read(processStateProvider.notifier).state = false;
    ref.read(progressValProvider.notifier).reset();
    ref.read(dataListProvider.notifier).reset();
    ref.read(scoreProvider.notifier).state = '-----';
    ref.read(saveVideoStateProvider.notifier).state = false;
    ref.read(inputThumbProvider.notifier).reset();
  }
}