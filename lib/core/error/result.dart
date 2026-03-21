import 'package:bitirme_projesi/core/error/failure.dart';

class Result<T> {
  const Result._({
    this.data,
    this.failure,
  });

  final T? data;
  final Failure? failure;

  bool get isSuccess => data != null;
  bool get isFailure => failure != null;

  static Result<T> success<T>(T data) => Result<T>._(data: data);
  static Result<T> fail<T>(Failure failure) => Result<T>._(failure: failure);
}
