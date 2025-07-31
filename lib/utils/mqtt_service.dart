import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/material.dart';

typedef MqttMessageHandler = void Function(String topic, String message);
typedef MqttTopicHandler = void Function(String topic);
typedef MqttVoidHandler = void Function();

class MqttService with ChangeNotifier {
  static final MqttService _instance = MqttService._internal();

  factory MqttService() => _instance;

  MqttService._internal();

  late final MqttServerClient client;
  final List<String> subscribedTopics = [];
  bool isListening = false;

  MqttVoidHandler? onConnectedCallback;
  MqttVoidHandler? onDisconnectedCallback;
  MqttTopicHandler? onSubscribedCallback;
  MqttTopicHandler? onUnsubscribedCallback;
  MqttMessageHandler? onMessageCallback;

  /// 连接到 MQTT Broker
  Future<bool> connect({
    required String broker,
    required String clientId,
    int port = 1883,
    bool secure = false,
    int keepAlivePeriod = 60,
    int connectTimeoutPeriod = 30,
  }) async {
    try {
      client = MqttServerClient(broker, clientId)
        ..port = port
        ..logging(on: true)
        ..keepAlivePeriod = keepAlivePeriod
        ..onDisconnected = _onDisconnected
        ..onConnected = _onConnected
        ..onSubscribed = _onSubscribed
        ..connectTimeoutPeriod = connectTimeoutPeriod
        ..secure = secure;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillTopic('willtopic')
          .withWillMessage('Client disconnected')
          .withWillQos(MqttQos.atLeastOnce)
          .startClean()
          .withWillRetain();
      client.connectionMessage = connMessage;

      print('正在连接 MQTT Broker...');
      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('MQTT 连接成功！');
        listenToMessages();
        notifyListeners();
        return true;
      } else {
        print('MQTT 连接失败: ${client.connectionStatus?.returnCode}');
        await disconnect();
        return false;
      }
    } catch (e, stackTrace) {
      print('MQTT 连接异常: $e');
      print('堆栈跟踪: $stackTrace');
      await disconnect();
      return false;
    }
  }

  /// 订阅主题
  Future<bool> subscribeToTopic(
    String topic, [
    MqttQos qos = MqttQos.atLeastOnce,
  ]) async {
    if (!isConnected) {
      print('MQTT 未连接，无法订阅主题');
      return false;
    }

    try {
      print('正在订阅主题: $topic');
      await client.subscribe(topic, qos);
      subscribedTopics.add(topic);
      return true;
    } catch (e) {
      print('订阅主题失败: $topic, 错误: $e');
      return false;
    }
  }

  /// 批量订阅主题
  Future<void> subscribeToTopics(
    List<String> topics, [
    MqttQos qos = MqttQos.atLeastOnce,
  ]) {
    return Future.wait(topics.map((topic) => subscribeToTopic(topic, qos)));
  }

  /// 取消订阅主题
  Future<bool> unsubscribeFromTopic(String topic) async {
    if (!isConnected) {
      print('MQTT 未连接，无法取消订阅主题');
      return false;
    }

    try {
      print('正在取消订阅主题: $topic');
      print('当前连接状态: ${client.connectionStatus?.state}');
      client.unsubscribe(topic);
      subscribedTopics.remove(topic);
      onUnsubscribedCallback?.call(topic);
      return true;
    } catch (e) {
      print('取消订阅主题失败: $topic, 错误: $e');
      return false;
    }
  }

  /// 发布消息
  Future<bool> publishMessage({
    required String topic,
    required String message,
    MqttQos qos = MqttQos.atLeastOnce,
    bool retain = false,
  }) async {
    if (!isConnected) {
      print('MQTT 未连接，无法发布消息');
      return false;
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      client.publishMessage(topic, qos, builder.payload!, retain: retain);
      return true;
    } catch (e) {
      print('发布消息失败: $topic, 错误: $e');
      return false;
    }
  }

  /// 监听消息
  void listenToMessages() {
    if (isListening) return;
    isListening = true;

    client.updates?.listen(
      (List<MqttReceivedMessage<MqttMessage>> messages) {
        try {
          final received = messages[0];
          final message = received.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            message.payload.message,
          );
          final topic = received.topic;

          print('收到消息: 主题: $topic, 消息: $payload');
          onMessageCallback?.call(topic, payload);
        } catch (e) {
          print('处理消息时出错: $e');
        }
      },
      onError: (error) {
        print('消息监听错误: $error');
        isListening = false;
      },
    );
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      if (isConnected) {
        client.disconnect();
      }
      subscribedTopics.clear();
      print('MQTT 已断开连接');
    } catch (e) {
      print('断开连接时出错: $e');
    }
  }

  /// 检查连接状态
  bool get isConnected =>
      client.connectionStatus?.state == MqttConnectionState.connected;

  /// 内部回调: 连接成功
  void _onConnected() {
    print('MQTT 连接成功！');
    onConnectedCallback?.call();
    notifyListeners(); // 通知状态变化
  }

  /// 内部回调: 断开连接
  void _onDisconnected() {
    print('MQTT 连接断开');
    onDisconnectedCallback?.call();
    notifyListeners(); // 通知状态变化
  }

  /// 内部回调: 订阅成功
  void _onSubscribed(String topic) {
    print('订阅成功: $topic');
    onSubscribedCallback?.call(topic);
  }
}
