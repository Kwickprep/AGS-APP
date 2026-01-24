import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/app_drawer.dart';
import 'home_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(LoadUserData()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dashboard_outlined,
                size: 100,
                color: AppColors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Coming Soon',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 32,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dashboard features are under development',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.grey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
