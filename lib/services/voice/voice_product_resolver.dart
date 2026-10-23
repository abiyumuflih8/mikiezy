import '../../models/mikiezy_models.dart';
import 'voice_product_name_normalizer.dart';

enum VoiceProductMatchType { exact, alias, fuzzy, ambiguous, notFound, invalid }

class VoiceProductCandidate {
  const VoiceProductCandidate({
    required this.product,
    required this.confidence,
  });

  final Product product;
  final double confidence;
}

class VoiceProductMatchResult {
  const VoiceProductMatchResult({
    required this.type,
    required this.spokenName,
    required this.normalizedName,
    required this.confidence,
    this.product,
    this.candidates = const [],
    this.message,
  });

  final VoiceProductMatchType type;
  final Product? product;
  final List<VoiceProductCandidate> candidates;
  final double confidence;
  final String spokenName;
  final String normalizedName;
  final String? message;

  bool get isMatched =>
      type == VoiceProductMatchType.exact ||
      type == VoiceProductMatchType.alias ||
      type == VoiceProductMatchType.fuzzy;
}

class VoiceProductResolver {
  const VoiceProductResolver({
    this.normalizer = const VoiceProductNameNormalizer(),
    this.autoMatchThreshold = 0.88,
    this.candidateThreshold = 0.72,
    this.ambiguityGap = 0.06,
  });

  final VoiceProductNameNormalizer normalizer;
  final double autoMatchThreshold;
  final double candidateThreshold;
  final double ambiguityGap;

  VoiceProductMatchResult resolve({
    required String spokenName,
    required List<Product> products,
    List<VoiceProductAlias> aliases = const [],
    String? matchedProductId,
    String? spokenUnit,
  }) {
    final normalizedName = normalizer.normalizeSpokenName(
      spokenName,
      spokenUnit: spokenUnit,
    );
    if (normalizedName.isEmpty) {
      return VoiceProductMatchResult(
        type: VoiceProductMatchType.invalid,
        spokenName: spokenName,
        normalizedName: normalizedName,
        confidence: 0,
        message: 'Nama produk belum terbaca jelas.',
      );
    }
    if (products.isEmpty) {
      return _notFound(spokenName, normalizedName);
    }

    final preMatched = _productById(products, matchedProductId);
    if (preMatched != null) {
      return _matched(
        VoiceProductMatchType.exact,
        spokenName,
        normalizedName,
        preMatched,
        1,
      );
    }

    final exact = products
        .where(
          (product) => normalizer.normalize(product.name) == normalizedName,
        )
        .toList();
    if (exact.length == 1) {
      return _matched(
        VoiceProductMatchType.exact,
        spokenName,
        normalizedName,
        exact.single,
        1,
      );
    }
    if (exact.length > 1) {
      return _ambiguous(spokenName, normalizedName, [
        for (final product in exact)
          VoiceProductCandidate(product: product, confidence: 1),
      ]);
    }

    final aliasTargets = _aliasTargets(
      normalizedName: normalizedName,
      products: products,
      aliases: aliases,
    );
    if (aliasTargets.length == 1) {
      return _matched(
        VoiceProductMatchType.alias,
        spokenName,
        normalizedName,
        aliasTargets.single,
        0.98,
      );
    }
    if (aliasTargets.length > 1) {
      return _ambiguous(spokenName, normalizedName, [
        for (final product in aliasTargets)
          VoiceProductCandidate(product: product, confidence: 0.98),
      ]);
    }

    final prefixCandidates = _variantPrefixCandidates(normalizedName, products);
    if (prefixCandidates.length > 1) {
      return _ambiguous(spokenName, normalizedName, prefixCandidates);
    }
    if (prefixCandidates.length == 1) {
      return _notFound(
        spokenName,
        normalizedName,
        candidates: prefixCandidates,
      );
    }

    final ranked = <VoiceProductCandidate>[];
    for (final product in products) {
      final score = _similarity(normalizedName, product.name);
      if (score >= candidateThreshold) {
        ranked.add(VoiceProductCandidate(product: product, confidence: score));
      }
    }
    ranked.sort((a, b) => b.confidence.compareTo(a.confidence));

    if (ranked.length > 1 &&
        ranked.first.confidence - ranked[1].confidence < ambiguityGap) {
      return _ambiguous(spokenName, normalizedName, ranked.take(5).toList());
    }
    if (ranked.isNotEmpty && ranked.first.confidence >= autoMatchThreshold) {
      final best = ranked.first;
      return _matched(
        VoiceProductMatchType.fuzzy,
        spokenName,
        normalizedName,
        best.product,
        best.confidence,
      );
    }

    return _notFound(
      spokenName,
      normalizedName,
      candidates: ranked.take(5).toList(),
    );
  }

  List<Product> _aliasTargets({
    required String normalizedName,
    required List<Product> products,
    required List<VoiceProductAlias> aliases,
  }) {
    final byId = <String, Product>{
      for (final product in products) product.id: product,
    };
    final targets = <String, Product>{};
    for (final alias in aliases) {
      final normalizedAlias = alias.normalizedAlias.trim().isEmpty
          ? normalizer.normalize(alias.aliasText)
          : normalizer.normalize(alias.normalizedAlias);
      if (normalizedAlias != normalizedName) continue;

      Product? target;
      final productId = alias.productId?.trim();
      if (productId != null && productId.isNotEmpty) {
        target = byId[productId];
      } else {
        final canonical = normalizer.normalize(alias.canonicalProductName);
        for (final product in products) {
          if (normalizer.normalize(product.name) == canonical) {
            target = product;
            break;
          }
        }
      }
      if (target != null) targets[target.id] = target;
    }
    return targets.values.toList();
  }

  List<VoiceProductCandidate> _variantPrefixCandidates(
    String query,
    List<Product> products,
  ) {
    if (normalizer.measurementSignature(query).isNotEmpty) return const [];
    final candidates = <VoiceProductCandidate>[];
    for (final product in products) {
      final name = normalizer.normalize(product.name);
      if (name.startsWith('$query ')) {
        candidates.add(
          VoiceProductCandidate(
            product: product,
            confidence: _similarity(
              query,
              product.name,
            ).clamp(0.72, 0.87).toDouble(),
          ),
        );
      }
    }
    return candidates;
  }

  double _similarity(String normalizedQuery, String productName) {
    final candidate = normalizer.normalize(productName);
    final queryMeasure = normalizer.measurementSignature(normalizedQuery);
    final candidateMeasure = normalizer.measurementSignature(candidate);
    if (queryMeasure.isNotEmpty &&
        candidateMeasure.isNotEmpty &&
        queryMeasure != candidateMeasure) {
      return 0;
    }

    final maxLength = normalizedQuery.length > candidate.length
        ? normalizedQuery.length
        : candidate.length;
    if (maxLength == 0) return 0;
    final editSimilarity =
        1 - (_levenshtein(normalizedQuery, candidate) / maxLength);
    final queryTokens = normalizedQuery.split(' ').toSet();
    final candidateTokens = candidate.split(' ').toSet();
    final union = queryTokens.union(candidateTokens).length;
    final tokenSimilarity = union == 0
        ? 0.0
        : queryTokens.intersection(candidateTokens).length / union;
    var score = editSimilarity > tokenSimilarity
        ? editSimilarity
        : tokenSimilarity;
    final blended = (editSimilarity * 0.7) + (tokenSimilarity * 0.3);
    if (blended > score) score = blended;
    if (queryMeasure.isNotEmpty && candidateMeasure.isEmpty) score *= 0.75;
    if (queryMeasure.isEmpty && candidateMeasure.isNotEmpty) score *= 0.92;
    return score.clamp(0, 1).toDouble();
  }

  int _levenshtein(String left, String right) {
    if (left == right) return 0;
    if (left.isEmpty) return right.length;
    if (right.isEmpty) return left.length;

    var previous = List<int>.generate(right.length + 1, (index) => index);
    for (var i = 0; i < left.length; i++) {
      final current = List<int>.filled(right.length + 1, 0);
      current[0] = i + 1;
      for (var j = 0; j < right.length; j++) {
        final substitutionCost = left.codeUnitAt(i) == right.codeUnitAt(j)
            ? 0
            : 1;
        final insertion = current[j] + 1;
        final deletion = previous[j + 1] + 1;
        final substitution = previous[j] + substitutionCost;
        current[j + 1] = insertion < deletion
            ? (insertion < substitution ? insertion : substitution)
            : (deletion < substitution ? deletion : substitution);
      }
      previous = current;
    }
    return previous.last;
  }

  Product? _productById(List<Product> products, String? productId) {
    final id = productId?.trim();
    if (id == null || id.isEmpty) return null;
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  VoiceProductMatchResult _matched(
    VoiceProductMatchType type,
    String spokenName,
    String normalizedName,
    Product product,
    double confidence,
  ) {
    return VoiceProductMatchResult(
      type: type,
      product: product,
      candidates: [
        VoiceProductCandidate(product: product, confidence: confidence),
      ],
      confidence: confidence,
      spokenName: spokenName,
      normalizedName: normalizedName,
    );
  }

  VoiceProductMatchResult _ambiguous(
    String spokenName,
    String normalizedName,
    List<VoiceProductCandidate> candidates,
  ) {
    final names = candidates
        .map((candidate) => candidate.product.name)
        .join(', ');
    return VoiceProductMatchResult(
      type: VoiceProductMatchType.ambiguous,
      candidates: candidates,
      confidence: candidates.isEmpty ? 0 : candidates.first.confidence,
      spokenName: spokenName,
      normalizedName: normalizedName,
      message: 'Produk "$spokenName" cocok dengan beberapa produk: $names.',
    );
  }

  VoiceProductMatchResult _notFound(
    String spokenName,
    String normalizedName, {
    List<VoiceProductCandidate> candidates = const [],
  }) {
    return VoiceProductMatchResult(
      type: VoiceProductMatchType.notFound,
      candidates: candidates,
      confidence: candidates.isEmpty ? 0 : candidates.first.confidence,
      spokenName: spokenName,
      normalizedName: normalizedName,
      message: 'Produk "$spokenName" belum ditemukan.',
    );
  }
}
