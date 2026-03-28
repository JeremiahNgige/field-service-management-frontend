import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';

import '../../bloc/job/job_cubit.dart';
import '../../router/app_router.dart';
import '../../widgets/empty_jobs_state.dart';
import '../../widgets/job_card.dart';
import '../../../data/models/job/job_model.dart';
import '../../../data/services/location_service.dart';
import '../../../utils/helpers.dart';
import '../../../utils/extensions.dart';

@RoutePage()
class JobsListPage extends StatefulWidget {
  const JobsListPage({super.key});

  @override
  State<JobsListPage> createState() => _JobsListPageState();
}

class _JobsListPageState extends State<JobsListPage> {
  final _scrollCtrl = ScrollController();
  Position? _userPosition;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    context.read<JobCubit>().loadJobs(refresh: true);
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
      context.read<JobCubit>().loadJobs();
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
        title: const Text('Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<JobCubit>().loadJobs(refresh: true),
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
              listenWhen: (previous, current) => previous.error != current.error && current.error != null && current.jobs.isNotEmpty,
              listener: (context, state) {
                context.showWarningSnackBar(
                    'Offline mode — showing cached jobs. ${state.error ?? ''}'
                    .trim());
              },
              builder: (context, state) {
                final unassignedJobs = state.jobs
                    .where((j) => j.status == JobStatus.unassigned)
                    .toList();

                if (state.isLoading && state.jobs.isEmpty) {
                  return _buildShimmer();
                }
                if (state.error != null && state.jobs.isEmpty) {
                  return EmptyJobsState(
                    icon: Icons.wifi_off_rounded,
                    message: 'Could not load jobs',
                    subtitle: 'Check your connection and try again.',
                    onRetry: () => context.read<JobCubit>().loadJobs(refresh: true),
                  );
                }
                if (unassignedJobs.isEmpty) {
                  return const EmptyJobsState(
                    message: 'No unassigned jobs',
                    subtitle: 'All available jobs have been assigned.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<JobCubit>().loadJobs(refresh: true),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: unassignedJobs.length + (state.jobsHasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == unassignedJobs.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final job = unassignedJobs[index];
                      return JobCard(
                        job: job,
                        statusColor: AppHelpers.statusColor(job.status),
                        priorityColor: AppHelpers.priorityColor(job.priority),
                        distanceMeters: _distanceTo(job),
                        onTap: () {
                          if (job.jobId != null) {
                            context.read<JobCubit>().selectJob(job.jobId!);
                            context.router.push(JobDetailRoute(jobId: job.jobId!));
                          }
                        },
                      );
                    },
                  ),
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
                  ? 'Location access permanently denied. Enable it in Settings to see distances.'
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
