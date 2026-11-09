import '../domain/brand.dart';
import '../domain/country.dart';
import '../domain/vehicle_model.dart';

/// Reference catalogue (architecture AD-08): bundled in the app and refreshed
/// from `GET /reference/catalog`. Screens only depend on this interface.
abstract interface class ReferenceRepository {
  Future<List<Country>> countries();

  Future<List<Brand>> brands();

  /// Ranked brand ids for each Popular list (D32, FR-REF-11).
  Future<Map<PopularListCode, List<String>>> popularLists();

  /// The brand's models, in the dataset's order (most popular first).
  /// Empty when the brand's models aren't loaded yet (FR-REF-12 phase 2).
  Future<List<VehicleModel>> models(String brandId);
}
