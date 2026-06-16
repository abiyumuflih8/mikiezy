import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/state/app_state.dart';

void main() {
  test('state persists changes through local repository contract', () async {
    final repository = MemoryMikiezyRepository();
    final firstState = MikiezyState.seeded(repository: repository);
    await firstState.hydrateFromLocal();

    await firstState.addProductCategory('Frozen Food');
    firstState.updateProfile(
      ownerName: 'Pemilik Baru',
      email: firstState.email,
      phone: firstState.phone,
      businessName: 'Toko Lokal',
      businessCategory: firstState.businessCategory,
      businessLocation: firstState.businessLocation,
    );
    await Future<void>.delayed(Duration.zero);

    final restoredState = MikiezyState.seeded(repository: repository);
    await restoredState.hydrateFromLocal();

    expect(restoredState.productCategories, contains('Frozen Food'));
    expect(restoredState.ownerName, 'Pemilik Baru');
    expect(restoredState.businessName, 'Toko Lokal');
  });
}
