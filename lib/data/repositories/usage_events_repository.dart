import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/supabase_config.dart';
import '../models/usage_event.dart';

/// Insert-only repository for the `usage_events` table.
///
/// `usage_events` is tenant-anonymous (no security boundary on tenant_id) and
/// readable only by `developer@attendix.de` per RLS, so this repo deliberately
/// skips the tenant-aware base class — no tenantId filter is applied.
class UsageEventsRepository {
  UsageEventsRepository(this._ref);

  final Ref _ref;

  Future<void> insert(UsageEvent event) async {
    final client = _ref.read(supabaseClientProvider);
    await client.from('usage_events').insert(event.toJson());
  }
}

final usageEventsRepositoryProvider = Provider<UsageEventsRepository>(
  UsageEventsRepository.new,
);
