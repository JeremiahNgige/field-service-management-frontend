import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../data/models/job/job_model.dart';
import '../../../data/repository/job_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class JobState extends Equatable {
  const JobState({
    this.jobs = const [],
    this.assignedJobs = const [],
    this.selectedJob,
    this.isLoading = false,
    this.error,
    this.jobsNextCursor,
    this.jobsHasMore = true,
    this.assignedJobsNextCursor,
    this.assignedJobsHasMore = true,
    this.uploadUrls,
  });

  final List<JobModel> jobs;
  final List<JobModel> assignedJobs;
  final JobModel? selectedJob;
  final bool isLoading;
  final String? error;
  
  // Separation of pagination state
  final String? jobsNextCursor;
  final bool jobsHasMore;
  
  final String? assignedJobsNextCursor;
  final bool assignedJobsHasMore;
  
  final UploadUrlsResponse? uploadUrls;

  JobState copyWith({
    List<JobModel>? jobs,
    List<JobModel>? assignedJobs,
    JobModel? selectedJob,
    bool? isLoading,
    String? error,
    String? jobsNextCursor,
    bool? jobsHasMore,
    String? assignedJobsNextCursor,
    bool? assignedJobsHasMore,
    UploadUrlsResponse? uploadUrls,
  }) => JobState(
    jobs: jobs ?? this.jobs,
    assignedJobs: assignedJobs ?? this.assignedJobs,
    selectedJob: selectedJob ?? this.selectedJob,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    jobsNextCursor: jobsNextCursor ?? this.jobsNextCursor,
    jobsHasMore: jobsHasMore ?? this.jobsHasMore,
    assignedJobsNextCursor: assignedJobsNextCursor ?? this.assignedJobsNextCursor,
    assignedJobsHasMore: assignedJobsHasMore ?? this.assignedJobsHasMore,
    uploadUrls: uploadUrls ?? this.uploadUrls,
  );

  @override
  List<Object?> get props => [
    jobs,
    assignedJobs,
    selectedJob,
    isLoading,
    error,
    jobsNextCursor,
    jobsHasMore,
    assignedJobsNextCursor,
    assignedJobsHasMore,
    uploadUrls,
  ];
}

// ─── HydratedCubit ───────────────────────────────────────────────────────────

/// [JobCubit] uses [HydratedCubit] so that in-progress job data (checklist
/// progress, offline queued posts) is persisted to local storage and
/// restored on app restart — ideal for technicians posting step-by-step.
@injectable
class JobCubit extends HydratedCubit<JobState> {
  JobCubit(this._jobRepository) : super(const JobState());

  final IJobRepository _jobRepository;

  // ── CRUD ────────────────────────────────────────────────────────────────

  Future<void> loadJobs({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.jobsHasMore) return;

    emit(state.copyWith(isLoading: true, error: null));

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(state.copyWith(isLoading: false, error: 'No internet connection.'));
      return;
    }

    final cursor = refresh ? null : state.jobsNextCursor;
    final result = await _jobRepository.listJobs(cursor: cursor);

    result.fold(
      (error) => emit(state.copyWith(isLoading: false, error: error)),
      (response) {
        final incomingJobs = response.data ?? [];
        final currentJobs = refresh ? <JobModel>[] : state.jobs;
        
        // Deduplicate jobs by mapping jobId
        final jobsMap = { for (var j in currentJobs) j.jobId!: j };
        for (var j in incomingJobs) {
          jobsMap[j.jobId!] = j;
        }

        emit(
          state.copyWith(
            isLoading: false,
            jobs: jobsMap.values.toList(),
            jobsHasMore: response.next != null,
            jobsNextCursor: response.next,
          ),
        );
      },
    );
  }

  Future<void> loadAssignedJobs({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.assignedJobsHasMore) return;

    emit(state.copyWith(isLoading: true, error: null));

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(state.copyWith(isLoading: false, error: 'No internet connection.'));
      return;
    }

    final cursor = refresh ? null : state.assignedJobsNextCursor;
    final result = await _jobRepository.fetchAssignedJobs(cursor: cursor);

    result.fold(
      (error) => emit(state.copyWith(isLoading: false, error: error)),
      (response) {
        final incomingJobs = response.data ?? [];
        final currentJobs = refresh ? <JobModel>[] : state.assignedJobs;
        
        // Deduplicate assigned jobs by mapping jobId
        final jobsMap = { for (var j in currentJobs) j.jobId!: j };
        for (var j in incomingJobs) {
          jobsMap[j.jobId!] = j;
        }

        emit(
          state.copyWith(
            isLoading: false,
            assignedJobs: jobsMap.values.toList(),
            assignedJobsHasMore: response.next != null,
            assignedJobsNextCursor: response.next,
          ),
        );
      },
    );
  }

  Future<void> selectJob(String jobId) async {
    // Optimistically set the job from local cache if it exists
    JobModel? localJob;
    try {
      localJob = state.jobs.firstWhere((j) => j.jobId == jobId);
    } catch (_) {
      try {
        localJob = state.assignedJobs.firstWhere((j) => j.jobId == jobId);
      } catch (_) {}
    }

    emit(state.copyWith(isLoading: true, error: null, selectedJob: localJob));

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(state.copyWith(isLoading: false, error: 'No internet connection.'));
      return;
    }

    final result = await _jobRepository.getJobDetail(jobId);
    result.fold(
      (error) => emit(state.copyWith(isLoading: false, error: error)),
      (job) => emit(state.copyWith(isLoading: false, selectedJob: job)),
    );
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _jobRepository.updateJob(jobId, data);
    result.fold(
      (error) => emit(state.copyWith(isLoading: false, error: error)),
      (updated) {
        final jobs = state.jobs
            .map((j) => j.jobId == jobId ? updated : j)
            .toList();
        emit(
          state.copyWith(isLoading: false, jobs: jobs, selectedJob: updated),
        );
      },
    );
  }

  Future<void> deleteJob(String jobId) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _jobRepository.deleteJob(jobId);
    result.fold(
      (error) => emit(state.copyWith(isLoading: false, error: error)),
      (_) {
        final jobs = state.jobs.where((j) => j.jobId != jobId).toList();
        emit(state.copyWith(isLoading: false, jobs: jobs));
      },
    );
  }

  Future<void> assignJob(String jobId, {String? currentUserId}) async {
    emit(state.copyWith(isLoading: true, error: null));

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(state.copyWith(isLoading: false, error: 'No internet connection.'));
      return;
    }

    final result = await _jobRepository.assignJob(jobId, currentUserId ?? '');
    result.fold(
      (error) => emit(state.copyWith(isLoading: false, error: error)),
      (job) {
        // Fallback to update assignedTo locally if API misses returning it
        final assignedJob = currentUserId != null && job.assignedTo == null
            ? JobModel.fromJson({
                ...job.toJson(),
                'assigned_to': currentUserId,
                'status': 'assigned',
              })
            : job;

        final jobs = state.jobs
            .map((j) => j.jobId == jobId ? assignedJob : j)
            .toList();

        final assignedJobs = [...state.assignedJobs];
        if (!assignedJobs.any((j) => j.jobId == jobId)) {
          assignedJobs.insert(0, assignedJob);
        } else {
          final index = assignedJobs.indexWhere((j) => j.jobId == jobId);
          assignedJobs[index] = assignedJob;
        }

        emit(
          state.copyWith(
            isLoading: false,
            selectedJob: assignedJob,
            jobs: jobs,
            assignedJobs: assignedJobs,
          ),
        );
      },
    );
  }

  Future<void> fetchUploadUrls(UploadUrlRequest request) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _jobRepository.generateUploadUrls(request);
    result.fold(
      (error) => emit(state.copyWith(isLoading: false, error: error)),
      (urls) => emit(state.copyWith(isLoading: false, uploadUrls: urls)),
    );
  }

  // ─── HydratedCubit serialization ────────────────────────────────────────

  @override
  JobState? fromJson(Map<String, dynamic> json) {
    try {
      final jobsJson = json['jobs'] as List<dynamic>? ?? [];
      final assignedJson = json['assignedJobs'] as List<dynamic>? ?? [];
      return JobState(
        jobs: jobsJson
            .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        assignedJobs: assignedJson
            .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        jobsNextCursor: json['jobsNextCursor'] as String?,
        jobsHasMore: json['jobsHasMore'] as bool? ?? true,
        assignedJobsNextCursor: json['assignedJobsNextCursor'] as String?,
        assignedJobsHasMore: json['assignedJobsHasMore'] as bool? ?? true,
      );
    } catch (_) {
      return const JobState();
    }
  }

  @override
  Map<String, dynamic>? toJson(JobState state) {
    return {
      'jobs': state.jobs.map((j) => j.toJson()).toList(),
      'assignedJobs': state.assignedJobs.map((j) => j.toJson()).toList(),
      'jobsNextCursor': state.jobsNextCursor,
      'jobsHasMore': state.jobsHasMore,
      'assignedJobsNextCursor': state.assignedJobsNextCursor,
      'assignedJobsHasMore': state.assignedJobsHasMore,
    };
  }
}
