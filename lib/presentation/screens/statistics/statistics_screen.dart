import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/presentation/presentation.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.statisticsTitle.tr(context: context)),
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
      ),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          if (state is StatisticsInitial || state is StatisticsLoading) {
            return const StatisticsShimmer();
          }
          final data = state is StatisticsLoaded
              ? state.data
              : StatisticsData.empty;
          return RefreshIndicator(
            onRefresh: context.read<StatisticsCubit>().load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.paddingXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TopStatsRow(data: data),
                  const SizedBox(height: AppConstants.paddingXXL),
                  ProgressCard(data: data),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
