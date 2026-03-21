import 'package:bitirme_projesi/features/text_recognition/data/datasources/text_recognition_data_source.dart';
import 'package:bitirme_projesi/features/text_recognition/data/repositories/text_recognition_repository_impl.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/repositories/text_recognition_repository.dart';
import 'package:bitirme_projesi/features/text_recognition/domain/usecases/recognize_text_usecase.dart';
import 'package:bitirme_projesi/features/text_recognition/presentation/cubit/text_recognition_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
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
}
