import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/di/service_locator.dart';
import 'package:til1m/data/datasources/local/progress_local_datasource.dart';
import 'package:til1m/data/datasources/remote/progress_remote_datasource.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';
import 'package:til1m/presentation/blocs/auth/auth_cubit.dart';
import 'package:til1m/presentation/blocs/home/home_cubit.dart';
import 'package:til1m/presentation/widgets/home/daily_progress_card.dart';
import 'package:til1m/presentation/widgets/home/home_header.dart';
import 'package:til1m/presentation/widgets/home/home_stats_row.dart';
import 'package:til1m/presentation/widgets/home/quick_actions_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(
        authRepo: sl<AuthRepository>(),
        localDataSource: sl<ProgressLocalDataSource>(),
        remoteDataSource: sl<ProgressRemoteDataSource>(),
      ),
      child: const _HomeView(),
    );
  }
}

final class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeInitial || state is HomeLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = (state as HomeLoaded).data;

            return RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().load(),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingL,
                  vertical: AppConstants.paddingXXL,
                ),
                children: [
                  HomeHeader(
                    data: data,
                    userName: context.read<AuthCubit>().currentUserName,
                  ),
                  const SizedBox(height: AppConstants.paddingXXL),
                  DailyProgressCard(data: data),
                  const SizedBox(height: AppConstants.paddingL),
                  QuickActionsRow(data: data),
                  const SizedBox(height: AppConstants.paddingXXL),
                  HomeStatsRow(data: data),
                  const SizedBox(height: AppConstants.paddingL),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
