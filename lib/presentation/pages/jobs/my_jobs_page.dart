import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';

import '../../bloc/job/job_cubit.dart';
import '../../bloc/job_filter/job_filter_cubit.dart';
import '../../bloc/job_filter/job_filter_state.dart';
import '../../router/app_router.dart';
import '../../widgets/empty_jobs_state.dart';
import '../../widgets/job_card.dart';
import '../../widgets/job_filter_sheet.dart';
import '../../../data/models/job/job_model.dart';
import '../../../data/services/location_service.dart';
import '../../../utils/extensions.dart';
import '../../../utils/helpers.dart';

@RoutePage()
class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  final _scrollCtrl = ScrollController();
  Position? _userPosition;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    context.read<JobCubit>().loadAssignedJobs(refresh: true);
    _scrollCtrl.addListener(_onScroll);
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final pos = await LocationService.instance.getPosition();
    if (!mounted) return;
    setState(() {
      _userPosition = pos;
      _locationDenied = pos == null;
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<JobCubit>().loadAssignedJobs();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  double? _distanceTo(JobModel job) {
    if (_userPosition == null) return null;
    final lat = job.address?.latLong?.latitude;
    final lng = job.address?.latLong?.longitude;
    if (lat == null || lng == null) return null;
    return LocationService.instance.calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      lat,
      lng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const JobFilterSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<JobCubit>().loadAssignedJobs(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_locationDenied)
            _LocationDeniedBanner(
              isPermanent: LocationService.instance.permissionDeniedPermanently,
              onRetry: _fetchLocation,
            ),
          Expanded(
            child: BlocConsumer<JobCubit, JobState>(
              listenWhen: (previous, current) =>
                  previous.error != current.error &&
                  current.error != null &&
                  current.assignedJobs.isNotEmpty,
              listener: (context, state) {
                context.showWarningSnackBar(
                    'Offline mode — data may be stale. ${state.error ?? ''}'
                    .trim());
              },
              builder: (context, state) {
                if (state.isLoading && state.assignedJobs.isEmpty) {
                  return _buildShimmer();
                }
                if (state.error != null && state.assignedJobs.isEmpty) {
                  return EmptyJobsState(
                    icon: Icons.wifi_off_rounded,
                    message: 'Could not load your jobs',
                    subtitle: 'Check your connection and try again.',
                    onRetry: () =>
                        context.read<JobCubit>().loadAssignedJobs(refresh: true),
                  );
                }

                return BlocBuilder<JobFilterCubit, JobFilterState>(
                  builder: (context, filterState) {
                    final now = DateTime.now();
                    var jobs = state.assignedJobs.where((j) {
                      final matchStatus =
                          filterState.selectedStatuses.isEmpty ||
                          (j.status != null &&
                              filterState.selectedStatuses.contains(j.status));
                      final matchPriority =
                          filterState.selectedPriorities.isEmpty ||
                          (j.priority != null &&
                              filterState.selectedPriorities.contains(j.priority));

                      final searchLower = filterState.searchQuery.toLowerCase();
                      final titleMatch =
                          j.title?.toLowerCase().contains(searchLower) ?? false;
                      final descMatch =
                          j.description?.toLowerCase().contains(searchLower) ?? false;
                      final customerMatch =
                          j.customerName?.toLowerCase().contains(searchLower) ??
                          false;
                      final streetMatch =
                          j.address?.street?.toLowerCase().contains(searchLower) ??
                          false;
                      final cityMatch =
                          j.address?.city?.toLowerCase().contains(searchLower) ??
                          false;
                      final matchSearch =
                          filterState.searchQuery.isEmpty ||
                          titleMatch ||
                          descMatch ||
                          customerMatch ||
                          streetMatch ||
                          cityMatch;

                      bool isOverdue = j.isOverdue == true;
                      if (!isOverdue &&
                          j.endTime != null &&
                          j.status != JobStatus.completed &&
                          j.status != JobStatus.cancelled) {
                        final endTimeParams = DateTime.tryParse(j.endTime!);
                        if (endTimeParams != null && endTimeParams.isBefore(now)) {
                          isOverdue = true;
                        }
                      }
                      final matchOverdue = !filterState.showOverdueOnly || isOverdue;

                      return matchStatus &&
                          matchPriority &&
                          matchSearch &&
                          matchOverdue;
                    }).toList();

                    jobs.sort((a, b) {
                      final aTime = a.startTime != null
                          ? DateTime.tryParse(a.startTime!)
                          : null;
                      final bTime = b.startTime != null
                          ? DateTime.tryParse(b.startTime!)
                          : null;
                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return filterState.sortBy == JobSortOption.dateAsc
                          ? aTime.compareTo(bTime)
                          : bTime.compareTo(aTime);
                    });

                    return Column(
                      children: [
                        if (filterState.selectedStatuses.isNotEmpty ||
                            filterState.selectedPriorities.isNotEmpty)
                          SizedBox(
                            height: 50,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                ...filterState.selectedStatuses.map(
                                  (s) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: InputChip(
                                      label: Text(s.name.capitalize),
                                      onDeleted: () => context
                                          .read<JobFilterCubit>()
                                          .toggleStatus(s),
                                    ),
                                  ),
                                ),
                                ...filterState.selectedPriorities.map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: InputChip(
                                      label: Text(p.name.capitalize),
                                      onDeleted: () => context
                                          .read<JobFilterCubit>()
                                          .togglePriority(p),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (filterState.searchQuery.isNotEmpty ||
                            filterState.showOverdueOnly)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              'Showing ${jobs.length} result(s)',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ),
                        Expanded(
                          child: jobs.isEmpty
                              ? const Center(
                                  child: Text('No assigned jobs match your filters.'),
                                )
                              : RefreshIndicator(
                                  onRefresh: () => context
                                      .read<JobCubit>()
                                      .loadAssignedJobs(refresh: true),
                                  child: ListView.separated(
                                    controller: _scrollCtrl,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: jobs.length +
                                        (state.assignedJobsHasMore ? 1 : 0),
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      if (index == jobs.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      final job = jobs[index];
                                      return JobCard(
                                        job: job,
                                        statusColor:
                                            AppHelpers.statusColor(job.status),
                                        priorityColor:
                                            AppHelpers.priorityColor(job.priority),
                                        distanceMeters: _distanceTo(job),
                                        onTap: () {
                                          if (job.jobId != null) {
                                            context.read<JobCubit>().selectJob(
                                              job.jobId!,
                                            );
                                            context.router.push(
                                              JobDetailRoute(jobId: job.jobId!),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─── Location Denied Banner ───────────────────────────────────────────────────

class _LocationDeniedBanner extends StatelessWidget {
  const _LocationDeniedBanner({required this.isPermanent, required this.onRetry});
  final bool isPermanent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.location_off_rounded, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPermanent
                  ? 'Location denied. Enable in Settings for distances.'
                  : 'Location unavailable. Distances cannot be shown.',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
          if (!isPermanent)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber.shade800,
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          if (isPermanent)
            TextButton(
              onPressed: () => Geolocator.openAppSettings(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber.shade800,
                padding: EdgeInsets.zero,
                minimumSize: const Size(60, 30),
              ),
              child: const Text('Settings', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
