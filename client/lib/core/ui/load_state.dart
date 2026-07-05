import '../error/app_failure.dart';

sealed class LoadState<T> {
  const LoadState();
}

class Loading<T> extends LoadState<T> {
  const Loading();
}

class Content<T> extends LoadState<T> {
  const Content(this.data, {this.refreshing = false});

  final T data;
  final bool refreshing;
}

class Empty<T> extends LoadState<T> {
  const Empty();
}

class Failure<T> extends LoadState<T> {
  const Failure(this.error);

  final AppFailure error;
}

class OfflineStale<T> extends LoadState<T> {
  const OfflineStale(this.data);

  final T data;
}

enum ActionStatus { idle, submitting }
