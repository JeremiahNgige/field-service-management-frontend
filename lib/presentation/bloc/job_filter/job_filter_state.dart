import 'package:equatable/equatable.dart';
import '../../../data/models/job/job_model.dart';

enum JobSortOption { dateAsc, dateDesc }

class JobFilterState extends Equatable {
  const JobFilterState({
    this.searchQuery = '',
    this.selectedStatuses = const [],
    this.selectedPriorities = const [],
    this.sortBy = JobSortOption.dateAsc,
    this.showOverdueOnly = false,
  });

  final String searchQuery;
  final List<JobStatus> selectedStatuses;
  final List<JobPriority> selectedPriorities;
  final JobSortOption sortBy;
  final bool showOverdueOnly;

  JobFilterState copyWith({
    String? searchQuery,
    List<JobStatus>? selectedStatuses,
    List<JobPriority>? selectedPriorities,
    JobSortOption? sortBy,
    bool? showOverdueOnly,
  }) {
    return JobFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedPriorities: selectedPriorities ?? this.selectedPriorities,
      sortBy: sortBy ?? this.sortBy,
      showOverdueOnly: showOverdueOnly ?? this.showOverdueOnly,
    );
  }

  @override
  List<Object> get props => [
        searchQuery,
        selectedStatuses,
        selectedPriorities,
        sortBy,
        showOverdueOnly,
      ];
}
