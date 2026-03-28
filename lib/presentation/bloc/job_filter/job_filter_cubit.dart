import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../data/models/job/job_model.dart';
import 'job_filter_state.dart';

@injectable
class JobFilterCubit extends Cubit<JobFilterState> {
  JobFilterCubit() : super(const JobFilterState());

  void toggleStatus(JobStatus status) {
    final current = List<JobStatus>.from(state.selectedStatuses);
    if (current.contains(status)) {
      current.remove(status);
    } else {
      current.add(status);
    }
    emit(state.copyWith(selectedStatuses: current));
  }

  void togglePriority(JobPriority priority) {
    final current = List<JobPriority>.from(state.selectedPriorities);
    if (current.contains(priority)) {
      current.remove(priority);
    } else {
      current.add(priority);
    }
    emit(state.copyWith(selectedPriorities: current));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setSortBy(JobSortOption option) {
    emit(state.copyWith(sortBy: option));
  }

  void toggleOverdue() {
    emit(state.copyWith(showOverdueOnly: !state.showOverdueOnly));
  }

  void clearFilters() {
    emit(const JobFilterState());
  }
}
