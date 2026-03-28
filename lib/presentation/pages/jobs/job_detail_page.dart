import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fsm_frontend/presentation/router/app_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../utils/helpers.dart';
import '../../../../utils/extensions.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/job/job_cubit.dart';
import '../../widgets/empty_jobs_state.dart';
import '../../../data/models/job/job_model.dart';
import '../../../data/services/location_service.dart';

@RoutePage()
class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key, @PathParam('jobId') required this.jobId});

  final String jobId;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  @override
  void initState() {
    super.initState();
    // Fire fresh fetch whenever this screen is generated or deep-linked into
    context.read<JobCubit>().selectJob(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Detail')),
      body: BlocBuilder<JobCubit, JobState>(
        builder: (context, state) {
          final job = state.selectedJob;

          if (state.isLoading && job == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && job == null) {
            return EmptyJobsState(
              icon: Icons.wifi_off_rounded,
              message: 'Could not load job',
              subtitle: state.error ?? 'Check your connection.',
              onRetry: () => context.read<JobCubit>().selectJob(widget.jobId),
            );
          }

          if (job == null) {
            return EmptyJobsState(
              icon: Icons.search_off_rounded,
              message: 'Job not found',
              subtitle: 'This job might have been deleted or is unavailable.',
              onRetry: () => context.read<JobCubit>().selectJob(widget.jobId),
            );
          }
          return Scaffold(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderCard(job: job),
                  const SizedBox(height: 16),
                  _ScheduleCard(job: job),
                  const SizedBox(height: 16),
                  _MapCard(job: job),
                  const SizedBox(height: 16),
                  _RequirementsCard(requirements: job.requirements),
                  const SizedBox(height: 16),
                  _PhotosSection(job: job),
                  const SizedBox(height: 16),
                  _SignatureSection(signatureUrl: job.signature),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<JobCubit, JobState>(
        builder: (context, state) {
          final job = state.selectedJob;
          if (job == null ||
              job.isOverdue == true ||
              job.status == JobStatus.cancelled ||
              job.status == JobStatus.completed) {
            return const SizedBox.shrink();
          }

          final bool showAssign = job.status == JobStatus.unassigned;

          final String title = showAssign ? 'Assign to Me' : 'Edit Job';
          final IconData icon = showAssign
              ? Icons.assignment_turned_in_rounded
              : Icons.edit_note_rounded;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: showAssign
                        ? [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ]
                        : [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: state.isLoading
                        ? null
                        : () {
                            if (showAssign) {
                              final authState = context.read<AuthBloc>().state;
                              final userId = authState is AuthAuthenticated
                                  ? authState.user?.userId
                                  : null;

                              context.read<JobCubit>().assignJob(
                                widget.jobId,
                                currentUserId: userId,
                              );
                            } else {
                              context.router.push(
                                EditJobRoute(jobId: widget.jobId),
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (state.isLoading && showAssign)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Icon(icon, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── UI Widgets ─────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title ?? 'No Title',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(
                  status: job.isOverdue == true
                      ? 'OVERDUE'
                      : (job.status?.name ?? 'Unknown'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (job.description != null) ...[
              Text(
                job.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (job.customerName != null)
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Customer',
                value: job.customerName!,
              ),
            if (job.phoneNumber != null)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: job.phoneNumber!,
              ),
            _InfoRow(
              icon: Icons.priority_high_rounded,
              label: 'Priority',
              value: job.priority?.name.toUpperCase() ?? 'UNKNOWN',
            ),
            if (job.price != null)
              _InfoRow(
                icon: Icons.payments_outlined,
                label: 'Pay',
                value:
                    '${job.currency ?? '\$'} ${job.price!.toStringAsFixed(2)}',
                valueColor: Colors.green.shade700,
                isBold: true,
              ),
            if (job.address != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${job.address?.street ?? ''}, ${job.address?.city ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Schedule (Local Time)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TimelineRow(
              isFirst: true,
              label: 'Scheduled Start',
              time: AppHelpers.formatDate(job.startTime),
            ),
            _TimelineRow(
              isLast: true,
              label: 'Scheduled End',
              time: AppHelpers.formatDate(job.endTime),
            ),
            if (job.createdAt != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'Created: ${AppHelpers.formatDate(job.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({this.requirements});
  final Map<String, dynamic>? requirements;

  @override
  Widget build(BuildContext context) {
    if (requirements == null || requirements!.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.construction_rounded, color: Colors.grey, size: 32),
                SizedBox(height: 8),
                Text(
                  'No requirements specified',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final notes = requirements!['notes'] as String?;
    final toolsRaw = requirements!['tools'];
    List<String> tools = [];
    if (toolsRaw is List) {
      tools = toolsRaw.map((e) => e.toString()).toList();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      color: Colors.orange.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.construction_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Requirements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (notes != null && notes.isNotEmpty) ...[
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(notes, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 16),
            ],
            if (tools.isNotEmpty) ...[
              const Text(
                'Tools Needed',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tools
                    .map(
                      (t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: Colors.orange.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = job.photos != null && job.photos!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Photos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(hasPhotos ? 16 : 32),
              child: hasPhotos
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount: job.photos!.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: job.photos![index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.5),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    AppHelpers.formatDate(job.createdAt),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No photos uploaded yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignatureSection extends StatelessWidget {
  const _SignatureSection({this.signatureUrl});
  final String? signatureUrl;

  @override
  Widget build(BuildContext context) {
    final hasSignature = signatureUrl != null && signatureUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Text(
            'Customer Signature',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: hasSignature
                ? CachedNetworkImage(
                    imageUrl: signatureUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey.withValues(alpha: 0.05),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              'Loading signature...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey.withValues(alpha: 0.05),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.draw_rounded,
                            color: Colors.grey,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load signature',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    height: 200,
                    color: Colors.transparent,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.draw_rounded,
                            color: Colors.grey,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No signature available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Tiny Components ─────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status.toLowerCase() == 'completed') color = Colors.green;
    if (status.toLowerCase() == 'in_progress') color = Colors.blue;
    if (status.toLowerCase() == 'unassigned') color = Colors.orange;
    if (status.toLowerCase() == 'overdue') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.time,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String time;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 2,
              height: 8,
              color: isFirst
                  ? Colors.transparent
                  : Colors.grey.withValues(alpha: 0.3),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst
                    ? Colors.blue
                    : (isLast ? Colors.green : Colors.grey),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            Container(
              width: 2,
              height: 24,
              color: isLast
                  ? Colors.transparent
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enterprise Map & Navigation Card
// ─────────────────────────────────────────────────────────────────────────────

class _MapCard extends StatefulWidget {
  const _MapCard({required this.job});
  final JobModel job;

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> with TickerProviderStateMixin {
  double? _distanceMeters;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchDistance();
  }

  Future<void> _fetchDistance() async {
    final lat = widget.job.address?.latLong?.latitude;
    final lng = widget.job.address?.latLong?.longitude;
    if (lat == null || lng == null) return;

    final pos = await LocationService.instance.getPosition();
    if (!mounted) return;
    if (pos != null) {
      setState(() {
        _distanceMeters = LocationService.instance
            .calculateDistance(pos.latitude, pos.longitude, lat, lng);
      });
    } else {
      setState(() => _locationDenied = true);
    }
  }



  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    if (job.address?.latLong == null ||
        job.address!.latLong!.latitude == null ||
        job.address!.latLong!.longitude == null) {
      return const SizedBox.shrink();
    }

    final lat = job.address!.latLong!.latitude!;
    final lng = job.address!.latLong!.longitude!;
    final location = LatLng(lat, lng);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fullAddress = [
      job.address?.street,
      job.address?.city,
      job.address?.state,
      job.address?.zip,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    // Return the Column directly since Google Map handles its own constraints.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Location & Routing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Spacer(),
              if (_distanceMeters != null)
                _InfoChip(
                  icon: Icons.near_me_rounded,
                  label: AppHelpers.formatDistance(_distanceMeters!),
                  color: cs.primary,
                ),
              if (_locationDenied)
                GestureDetector(
                  onTap: () => Geolocator.openAppSettings(),
                  child: _InfoChip(
                    icon: Icons.location_off_rounded,
                    label: 'Enable location',
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Map ──────────────────────────────────────────────────
              SizedBox(
                height: 260,
                width: double.infinity,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: location,
                        zoom: 15.5,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('job_destination'),
                          position: location,
                          infoWindow: InfoWindow(
                            title: job.title ?? 'Job Destination',
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      },
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      liteModeEnabled: false,
                      trafficEnabled: false,
                    ),
                    // ── Top address overlay ──────────────────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(isDark ? 160 : 130),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                fullAddress.isNotEmpty ? fullAddress : 'No Address',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(color: Colors.black54, blurRadius: 4),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── Coordinate badge ─────────────────────────────
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Action row ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => AppHelpers.launchNavigation(lat, lng),
                        icon: const Icon(Icons.navigation_rounded, size: 18),
                        label: const Text('Navigate'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: fullAddress.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: fullAddress));
                                if (context.mounted) {
                                  context.showInfoSnackBar('Address copied to clipboard');
                                }
                              },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy Address'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Reusable info chip ───────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
