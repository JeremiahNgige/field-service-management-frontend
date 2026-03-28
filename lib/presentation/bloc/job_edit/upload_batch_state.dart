part of 'upload_batch_cubit.dart';

abstract class UploadBatchState extends Equatable {
  const UploadBatchState();

  @override
  List<Object?> get props => [];
}

class UploadBatchInitial extends UploadBatchState {
  const UploadBatchInitial();
}

class UploadBatchInProgress extends UploadBatchState {
  const UploadBatchInProgress();
}

class UploadBatchSuccess extends UploadBatchState {
  const UploadBatchSuccess();
}

class UploadBatchFailure extends UploadBatchState {
  const UploadBatchFailure({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}
