import 'package:flutter/cupertino.dart';
import 'package:openai_dart/openai_dart.dart';

import '../data/DataController.dart';

// 생성형 ai 로 러닝 데이터 분석 답변 받아오는 싱글톤 객체
// 사용하기전에 객체 생성한 후, AI.initialize() 꼭 실행해줘야함.
class AI {
  AI._internal();

  static final AI instance = AI._internal();

  late final OpenAIClient _client;

  bool initialized = false;

  static final Map<String,String> url = {
    "openai" : "https://api.openai.com/v1/",
    "mindlogic" : "https://factchat-cloud.mindlogic.ai/v1/gateway"
  };
  static final Map<String,String> aiModel = {
    "basic1" : "gpt-5.6-luna",
    "basic2" : "gpt-5.4-nano"
  };

  static const String _systemPrompt = '''
  너는 사용자의 러닝 데이터를 분석해주는 데이터야
  아래 규칙에 맞게 응답해줘
  - 질문으로 들어오는 러닝 데이터를 분석해서 사용자 러닝의 질을 평가할 것
  - 판단한 이유와, 모범적인 수치를 간단하게 답변할 것
  - 100에서 200자 내외로 답변할 것
  - 해요체로 답변할 것
  ''';

  void logRed(String message) {
    debugPrint('\x1B[31m$message\x1B[0m');
  }

  void logGreen(String message) {
    debugPrint('\x1B[32m$message\x1B[0m');
  }

  Future<void> initialize() async {
    if (initialized) return;
    String? apiKey;
    final Pref pref = Pref();
    apiKey = await pref.getApiKey();
    if(apiKey == null || apiKey == "") return;
    logRed("==================\n\n\n\n\n");
    logGreen(apiKey);

    _client = OpenAIClient(
      config: OpenAIConfig(
        authProvider: ApiKeyProvider(apiKey),
        baseUrl: "https://factchat-cloud.mindlogic.ai/v1/gateway"
      )
    );
    initialized = true;
  }


  Future<String> ask(String question) async {
    if (!initialized) {
      throw StateError(
        'AI 초기화 안됨 AI.instance.initialize() 필요 ',
      );
    }
    final response = await _client.responses.create(
      CreateResponseRequest(
        model: aiModel["basic1"]!,
        instructions: _systemPrompt,
        input: ResponseInput.text(question),
      ),
    );

    return response.outputText;
  }
  /// 답변이 촤라라락
  Stream<String> askStream(String question) async* {
    if (!initialized) {
      throw StateError(
        'AI 초기화 안됨 AI.instance.initialize() 필요 ',
      );
    }
    try {
      final stream = _client.responses.createStream(
        CreateResponseRequest(
          model: aiModel["basic1"]!,
          instructions: _systemPrompt,
          input: ResponseInput.text(question),
          stream: true,
        ),
      );
      await for (final delta in stream.textDeltas()) {
        yield delta;
      }
    } catch (e,stackTree) {
      //
    }
  }

  void dispose() {
    _client.close();
  }
}