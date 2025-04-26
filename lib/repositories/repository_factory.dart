import 'debt_repository.dart';
import 'local/hive_debt_repository.dart';

enum StorageType {
  local,
  cloud, // Will be implemented later
}

class RepositoryFactory {
  static DebtRepository getDebtRepository(StorageType type) {
    switch (type) {
      case StorageType.local:
        return HiveDebtRepository();
      case StorageType.cloud:
        // TODO: Implement cloud repository
        throw UnimplementedError('Cloud storage not yet implemented');
    }
  }
}
