import 'package:bitirme_projesi/features/text_recognition/data/datasources/text_recognition_data_source.dart';
import 'package:bitirme_projesi/features/text_recognition/data/repositories/text_recognition_repository_impl.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/repositories/text_recognition_repository.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/usecases/recognize_text_usecase.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:bitirme_projesi/features/translation/data/datasources/translation_data_source.dart';
import 'package:bitirme_projesi/features/translation/data/repositories/translation_repository_impl.dart';
import 'package:bitirme_projesi/features/translation/domain/repositories/translation_repository.dart';
import 'package:bitirme_projesi/features/translation/domain/usecases/translate_text_usecase.dart';
import 'package:bitirme_projesi/features/translation/presentation/cubit/translation_cubit.dart';

import 'package:bitirme_projesi/features/cultural_context/data/datasources/cultural_context_data_source.dart';
import 'package:bitirme_projesi/features/cultural_context/data/repositories/cultural_context_repository_impl.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/repositories/cultural_context_repository.dart';
import 'package:bitirme_projesi/features/cultural_context/domain/usecases/get_cultural_context_usecase.dart';
import 'package:bitirme_projesi/features/cultural_context/presentation/cubit/cultural_context_cubit.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<http.Client>(() => http.Client());

  sl.registerLazySingleton<TextRecognizer>(
    () => TextRecognizer(script: TextRecognitionScript.latin),
  );

  sl.registerLazySingleton<TextRecognitionDataSource>(
    () => TextRecognitionDataSourceImpl(sl<TextRecognizer>()),
  );

  sl.registerLazySingleton<TextRecognitionRepository>(
    () => TextRecognitionRepositoryImpl(sl<TextRecognitionDataSource>()),
  );

  sl.registerLazySingleton<RecognizeTextUseCase>(
    () => RecognizeTextUseCase(sl<TextRecognitionRepository>()),
  );

  sl.registerFactory<TextRecognitionCubit>(
    () => TextRecognitionCubit(sl<RecognizeTextUseCase>()),
  );

  sl.registerLazySingleton<TranslationDataSource>(
    () => DeepLTranslationDataSource(sl<http.Client>()),
  );

  sl.registerLazySingleton<TranslationRepository>(
    () => TranslationRepositoryImpl(sl<TranslationDataSource>()),
  );

  sl.registerLazySingleton<TranslateTextUseCase>(
    () => TranslateTextUseCase(sl<TranslationRepository>()),
  );

  sl.registerFactory<TranslationCubit>(
    () => TranslationCubit(sl<TranslateTextUseCase>()),
  );

  sl.registerLazySingleton<CulturalContextDataSource>(
    () => CulturalContextDataSourceImpl(sl<http.Client>()),
  );

  sl.registerLazySingleton<CulturalContextRepository>(
    () => CulturalContextRepositoryImpl(sl<CulturalContextDataSource>()),
  );

  sl.registerLazySingleton<GetCulturalContextUseCase>(
    () => GetCulturalContextUseCase(sl<CulturalContextRepository>()),
  );

  sl.registerFactory<CulturalContextCubit>(
    () => CulturalContextCubit(sl<GetCulturalContextUseCase>()),
  );
}
