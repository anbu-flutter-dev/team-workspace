import 'package:team_workspace/core/error/failure.dart';

/// Hand-rolled result type — reads cleaner at call sites than dartz's Either
/// and avoids pulling in a functional-programming dependency for one type.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

extension ResultX<T> on Result<T> {
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    final self = this;
    return switch (self) {
      Ok<T>() => onSuccess(self.value),
      Err<T>() => onFailure(self.failure),
    };
  }
}
