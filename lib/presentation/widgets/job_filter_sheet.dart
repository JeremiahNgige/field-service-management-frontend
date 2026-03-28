import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/job/job_model.dart';
import '../../../utils/extensions.dart';
import '../bloc/job_filter/job_filter_cubit.dart';
import '../bloc/job_filter/job_filter_state.dart';

class JobFilterSheet extends StatelessWidget {
  const JobFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        ),
        child: BlocBuilder<JobFilterCubit, JobFilterState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter & Sort',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<JobFilterCubit>().clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by customer, address, or title...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    controller: TextEditingController(text: state.searchQuery)
                      ..selection = TextSelection.collapsed(offset: state.searchQuery.length),
                    onChanged: (val) => context.read<JobFilterCubit>().setSearchQuery(val),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overdue Jobs Only', style: Theme.of(context).textTheme.titleMedium),
                      Switch(
                        value: state.showOverdueOnly,
                        onChanged: (val) => context.read<JobFilterCubit>().toggleOverdue(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<JobSortOption>(
                    segments: const [
                      ButtonSegment(value: JobSortOption.dateDesc, label: Text('Newest First')),
                      ButtonSegment(value: JobSortOption.dateAsc, label: Text('Oldest First')),
                    ],
                    selected: {state.sortBy},
                    onSelectionChanged: (set) => context.read<JobFilterCubit>().setSortBy(set.first),
                  ),
                  const SizedBox(height: 24),
                Text('Status', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: JobStatus.values.map((status) {
                    final isSelected = state.selectedStatuses.contains(status);
                    return FilterChip(
                      label: Text(status.name.replaceAll('_', ' ').capitalize),
                      selected: isSelected,
                      selectedColor: status.color.withOpacity(0.2),
                      checkmarkColor: status.color,
                      labelStyle: TextStyle(
                        color: isSelected ? status.color : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                      onSelected: (_) {
                        context.read<JobFilterCubit>().toggleStatus(status);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text('Priority', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: JobPriority.values.map((priority) {
                    final isSelected = state.selectedPriorities.contains(priority);
                    return FilterChip(
                      label: Text(priority.name.capitalize),
                      selected: isSelected,
                      selectedColor: priority.color.withOpacity(0.2),
                      checkmarkColor: priority.color,
                      labelStyle: TextStyle(
                        color: isSelected ? priority.color : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                      onSelected: (_) {
                        context.read<JobFilterCubit>().togglePriority(priority);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Options'),
                  ),
                ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
