import '../data/models/job/job_model.dart';
import '../data/models/user/user_model.dart';

/// Dummy data for UI prototyping and testing.
class DummyData {
  DummyData._();

  static final UserModel dummyUser = UserModel(
    userId: '00000000-0000-0000-0000-000000000001',
    username: 'John Technician',
    email: 'john@fsm.com',
    phoneNumber: '0712345678',
    address: '123 Main Street, Nairobi',
    userType: 'technician',
    profilePicture: null,
    dateJoined: DateTime.now().toIso8601String(),
    lastLogin: DateTime.now().toIso8601String(),
  );

  static final List<JobModel> dummyJobs = [
    JobModel(
      jobId: '00000000-0000-0000-0000-000000000001',
      title: 'HVAC Installation',
      description: 'Install new HVAC system at client premises.',
      status: JobStatus.unassigned,
      priority: JobPriority.high,
      assignedTo: '00000000-0000-0000-0000-000000000001',
      phoneNumber: '0712345678',
      address: const Address(street: '456 River Road', city: 'Nairobi'),
      startTime: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      endTime: DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
      currency: 'USD',
      price: 250.00,
    ),
    JobModel(
      jobId: '00000000-0000-0000-0000-000000000002',
      title: 'Electrical Wiring Repair',
      description: 'Fix faulty wiring in office building.',
      status: JobStatus.inProgress,
      priority: JobPriority.medium,
      assignedTo: '00000000-0000-0000-0000-000000000001',
      phoneNumber: '0798765432',
      address: const Address(street: '789 Westlands Ave', city: 'Nairobi'),
      startTime: DateTime.now().toIso8601String(),
      endTime: DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
      currency: 'USD',
      price: 120.50,
    ),
  ];
}
