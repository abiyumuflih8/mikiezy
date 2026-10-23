import 'voice_command.dart';
import 'voice_create_product_entity_extractor.dart';
import 'voice_entity_extractor.dart';
import 'voice_intent_classifier.dart';
import 'voice_price_update_entity_extractor.dart';
import 'voice_stock_increment_entity_extractor.dart';
import 'voice_text_normalizer.dart';

class VoiceCommandRouter {
  const VoiceCommandRouter({
    this.normalizer = const VoiceTextNormalizer(),
    this.intentClassifier = const VoiceIntentClassifier(),
    this.entityExtractor = const VoiceEntityExtractor(),
    this.createProductEntityExtractor =
        const VoiceCreateProductEntityExtractor(),
    this.stockIncrementEntityExtractor =
        const VoiceStockIncrementEntityExtractor(),
    this.priceUpdateEntityExtractor = const VoicePriceUpdateEntityExtractor(),
  });

  final VoiceTextNormalizer normalizer;
  final VoiceIntentClassifier intentClassifier;
  final VoiceEntityExtractor entityExtractor;
  final VoiceCreateProductEntityExtractor createProductEntityExtractor;
  final VoiceStockIncrementEntityExtractor stockIncrementEntityExtractor;
  final VoicePriceUpdateEntityExtractor priceUpdateEntityExtractor;

  VoiceCommand route(String transcript) {
    final normalized = normalizer.normalize(transcript);
    final classification = intentClassifier.classify(normalized);
    var entities = entityExtractor.extract(
      normalizedText: normalized,
      intent: classification.intent,
    );
    if (classification.intent == VoiceCommandIntent.createProduct) {
      entities = entities.merge(
        createProductEntityExtractor.extract(normalized),
      );
    } else if (classification.intent ==
        VoiceCommandIntent.incrementProductStock) {
      entities = entities.merge(
        stockIncrementEntityExtractor.extract(normalized),
      );
    } else if (classification.intent == VoiceCommandIntent.updateProduct) {
      entities = entities.merge(priceUpdateEntityExtractor.extract(normalized));
    }
    return VoiceCommand(
      rawText: transcript,
      normalizedText: normalized,
      intent: classification.intent,
      entities: entities,
      confidence: classification.confidence,
      hasMultipleIntents: _hasMultipleIntents(normalized),
    );
  }

  bool _hasMultipleIntents(String normalizedText) {
    final segments = normalizedText
        .split(RegExp(r'\b(?:lalu|kemudian)\b'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty);
    var recognizedSegments = 0;
    for (final segment in segments) {
      if (intentClassifier.classify(segment).intent ==
          VoiceCommandIntent.unknown) {
        continue;
      }
      recognizedSegments += 1;
      if (recognizedSegments > 1) return true;
    }
    return false;
  }
}
