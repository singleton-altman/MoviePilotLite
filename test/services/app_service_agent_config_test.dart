import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/login/models/login_response.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

void main() {
  test('agent entry defaults to hidden before global config is applied', () {
    final service = AppService();

    expect(service.canShowAiAgentEntry, isFalse);
  });

  test(
    'agent entry requires login session and follows global user config flags',
    () {
      final service = AppService();

      service.applyUserGlobalConfig({
        'AI_AGENT_ENABLE': true,
        'AI_AGENT_HIDE_ENTRY': false,
        'LLM_SUPPORT_AUDIO_INPUT': true,
        'LLM_SUPPORT_AUDIO_OUTPUT': false,
        'AI_RECOMMEND_ENABLED': true,
      });

      expect(service.canShowAiAgentEntry, isFalse);

      service.saveProfile(
        'https://server.example',
        const LoginResponse(
          accessToken: 'token',
          tokenType: 'bearer',
          userId: 1,
          userName: 'alice',
          level: 1,
          permissions: {},
        ),
      );

      expect(service.canShowAiAgentEntry, isTrue);
      expect(service.llmSupportAudioInput.value, isTrue);
      expect(service.llmSupportAudioOutput.value, isFalse);
      expect(service.aiRecommendEnabled.value, isTrue);

      service.applyUserGlobalConfig({
        'AI_AGENT_ENABLE': true,
        'AI_AGENT_HIDE_ENTRY': true,
      });

      expect(service.canShowAiAgentEntry, isFalse);
    },
  );

  test('agent entry and feature flags reset on logout', () {
    final service = AppService();

    service.saveProfile(
      'https://server.example',
      const LoginResponse(
        accessToken: 'token',
        tokenType: 'bearer',
        userId: 1,
        userName: 'alice',
        level: 1,
        permissions: {},
      ),
    );
    service.applyUserGlobalConfig({
      'AI_AGENT_ENABLE': true,
      'AI_AGENT_HIDE_ENTRY': false,
      'LLM_SUPPORT_AUDIO_INPUT': true,
      'LLM_SUPPORT_AUDIO_OUTPUT': true,
      'AI_RECOMMEND_ENABLED': true,
    });

    expect(service.canShowAiAgentEntry, isTrue);

    service.clearLoginState();

    expect(service.canShowAiAgentEntry, isFalse);
    expect(service.agentCacheScopeKey.value, isEmpty);
    expect(service.llmSupportAudioInput.value, isFalse);
    expect(service.llmSupportAudioOutput.value, isFalse);
    expect(service.aiRecommendEnabled.value, isFalse);
  });
}
