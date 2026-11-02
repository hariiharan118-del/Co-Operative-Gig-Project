import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/verification_state.dart';

final verificationProvider =
    NotifierProvider<VerificationNotifier, VerificationState>(
  VerificationNotifier.new,
);

class VerificationNotifier extends Notifier<VerificationState> {
  @override
  VerificationState build() {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        load();
      } else if (next is AuthUnauthenticated || next is AuthError) {
        state = const VerificationState.unknown();
      }
    });

    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) {
      Future.microtask(load);
    }
    return const VerificationState.unknown();
  }

  Future<void> load() async {
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.dio.get<Map<String, dynamic>>('/workers/verification-status');
      if (response.data != null) {
        state = VerificationState.fromJson(response.data!);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        state = const VerificationState.unknown();
      } else {
        if (state.status == VerificationStatus.unknown) {
          state =
              const VerificationState(status: VerificationStatus.registered);
        }
      }
    } catch (_) {
      if (state.status == VerificationStatus.unknown) {
        state = const VerificationState(status: VerificationStatus.registered);
      }
    }
  }

  Future<bool> applyForVerification({
    String? primaryCategoryId,
    int? yearsOfExperience,
    String? learningMethod,
    String? previousExperience,
    List<Map<String, dynamic>>? references,
    List<Map<String, dynamic>>? evidences,
  }) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post<Map<String, dynamic>>(
        '/workers/verification/apply',
        data: {
          if (primaryCategoryId != null) 'primaryCategoryId': primaryCategoryId,
          if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
          if (learningMethod != null) 'learningMethod': learningMethod,
          if (previousExperience != null)
            'previousExperience': previousExperience,
          if (references != null) 'references': references,
          if (evidences != null) 'evidences': evidences,
        },
      );
      if (response.data != null) {
        state = VerificationState.fromJson(response.data!);
      } else {
        await load();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitPracticalCheck({
    required String description,
    String? title,
    String? videoUrl,
  }) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post<Map<String, dynamic>>(
        '/workers/evidence/practical-check',
        data: {
          'title': title ?? 'Practical Demonstration',
          'description': description,
          if (videoUrl != null) 'videoUrl': videoUrl,
        },
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
