import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
