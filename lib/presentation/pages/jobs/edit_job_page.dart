import 'dart:async';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../utils/helpers.dart';
import 'package:signature/signature.dart';

import '../../../../di/di.dart';
import '../../../data/models/job/local_photo.dart';
import '../../bloc/job/job_cubit.dart';
import '../../bloc/job_edit/image_capture_cubit.dart';
import '../../bloc/job_edit/upload_batch_cubit.dart';
import '../../router/app_router.dart';
import '../../../../utils/extensions.dart';

@RoutePage()
class EditJobPage extends StatelessWidget {
  const EditJobPage({super.key, @PathParam('jobId') required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ImageCaptureCubit>()),
        BlocProvider(create: (_) => getIt<UploadBatchCubit>()),
      ],
      child: _EditJobView(jobId: jobId),
    );
  }
}

class _EditJobView extends StatefulWidget {
  const _EditJobView({required this.jobId});

  final String jobId;

  @override
  State<_EditJobView> createState() => _EditJobViewState();
}

class _EditJobViewState extends State<_EditJobView> {
  late final SignatureController _signatureController;

  @override
  void initState() {
    super.initState();

    final cubit = context.read<ImageCaptureCubit>();
    final savedPointsRaw = cubit.state.signaturesMap[widget.jobId] ?? [];

    final savedPoints = savedPointsRaw.map((p) {
      return Point(
        Offset(p['dx'] as double, p['dy'] as double),
        PointType.values[p['type'] as int],
        p['pressure'] as double,
      );
    }).toList();

    _signatureController = SignatureController(
      points: savedPoints,
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );

    _signatureController.addListener(() {
      context.read<ImageCaptureCubit>().updateSignature(
        widget.jobId,
        _signatureController.points,
      );
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final result = await context.router.push(const CameraCaptureRoute());
    if (result != null && result is LocalPhoto) {
      if (mounted) {
        context.read<ImageCaptureCubit>().addPhoto(widget.jobId, result);
      }
    }
  }

  Future<void> _uploadBatch() async {
    final photos = context.read<ImageCaptureCubit>().state.photosMap[widget.jobId] ?? [];

    Uint8List? sigBytes;
    if (_signatureController.isNotEmpty) {
      sigBytes = await _signatureController.toPngBytes();
    }

    if (mounted) {
      context.read<UploadBatchCubit>().executeBatchUpload(
        jobId: widget.jobId,
        photos: photos,
        signatureBytes: sigBytes,
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadBatchCubit, UploadBatchState>(
      listener: (context, state) {
        if (state is UploadBatchFailure) {
          context.showErrorSnackBar(state.error);
        } else if (state is UploadBatchSuccess) {
          context.read<JobCubit>().selectJob(widget.jobId);
          context.read<ImageCaptureCubit>().clearCache(widget.jobId);
          context.router.pop();
          context.showSuccessSnackBar('Job updated & media uploaded successfully!');
        }
      },
      builder: (context, uploadState) {
        final isUploading = uploadState is UploadBatchInProgress;

        return Scaffold(
          appBar: AppBar(title: const Text('Edit Job')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPhotosCard(),
                const SizedBox(height: 16),
                _buildSignatureCard(),
                const SizedBox(height: 100), // padding for bottom button
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: isUploading ? null : _uploadBatch,
                  child: isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            AnimatedUploadingText(),
                          ],
                        )
                      : const Text(
                          'Upload & Complete Job',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotosCard() {
    return BlocBuilder<ImageCaptureCubit, ImageCaptureState>(
      builder: (context, state) {
        final photos = state.photosMap[widget.jobId] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Photos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                if (photos.isNotEmpty)
                  TextButton(
                    onPressed: () => context.read<ImageCaptureCubit>().clearPhotos(widget.jobId),
                    child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: photos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _capturePhoto,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.blue),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final photo = photos[index - 1];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                         fit: StackFit.expand,
                         children: [
                           Image.file(photo.file, fit: BoxFit.cover),
                           Positioned(
                             top: 0,
                             left: 0,
                             right: 0,
                             height: 48,
                             child: Container(
                               decoration: BoxDecoration(
                                 gradient: LinearGradient(
                                   begin: Alignment.topCenter,
                                   end: Alignment.bottomCenter,
                                   colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
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
                                 AppHelpers.formatDateTime(photo.capturedAt),
                                 textAlign: TextAlign.center,
                                 style: const TextStyle(
                                   color: Colors.white,
                                   fontSize: 10,
                                   fontWeight: FontWeight.bold,
                                   shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                 ),
                               ),
                             ),
                           ),
                           Positioned(
                             top: 4,
                             right: 4,
                             child: Material(
                               color: Colors.black.withValues(alpha: 0.5),
                               shape: const CircleBorder(),
                               clipBehavior: Clip.antiAlias,
                               child: InkWell(
                                 onTap: () => context.read<ImageCaptureCubit>().removePhoto(widget.jobId, photo),
                                 child: const Padding(
                                   padding: EdgeInsets.all(6),
                                   child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                 ),
                               ),
                             ),
                           ),
                         ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignatureCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Customer Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            TextButton(
              onPressed: () {
                _signatureController.clear();
                context.read<ImageCaptureCubit>().clearSignature(widget.jobId);
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Signature(
              controller: _signatureController,
              height: 200,
              backgroundColor: Colors.grey.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedUploadingText extends StatefulWidget {
  const AnimatedUploadingText({super.key});

  @override
  State<AnimatedUploadingText> createState() => _AnimatedUploadingTextState();
}

class _AnimatedUploadingTextState extends State<AnimatedUploadingText> {
  final List<String> _steps = const [
    'Uploading images...',
    'Saving signature...',
    'Completing job...',
  ];
  int _currentIndex = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1, milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _steps.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.5),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        _steps[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
