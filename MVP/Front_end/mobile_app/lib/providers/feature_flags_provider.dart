import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feature_flags_service.dart';

final featureFlagsProvider = Provider<FeatureFlagsService>((ref) => FeatureFlagsService.instance);
