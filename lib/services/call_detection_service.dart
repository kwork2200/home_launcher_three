import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../screens/call_screen.dart';
import 'dart:async';

class _LifecycleObserver with WidgetsBindingObserver {
  final CallDetectionService service;
  
  _LifecycleObserver(this.service);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    service.onAppLifecycleChanged(state);
  }
}

class CallDetectionService {
  static const MethodChannel _callEventChannel = 
      MethodChannel('com.kayfahaarukku.homelauncherthree/call_events');
  
  static final CallDetectionService _instance = CallDetectionService._internal();
  factory CallDetectionService() => _instance;
  
  CallDetectionService._internal();
  
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;
  Map<String, dynamic>? _pendingCallScreen;
  Timer? _pendingCallTimer;
  AppLifecycleState? _lastLifecycleState;
  
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    _callEventChannel.setMethodCallHandler(_handleCallEvent);
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this));

  }
  
  void onAppLifecycleChanged(AppLifecycleState state) {
    print('App lifecycle changed: $state');
    _lastLifecycleState = state;
    
    if (state == AppLifecycleState.resumed && _pendingCallScreen != null) {
      print('App resumed, attempting to show pending call screen');
      _tryShowCallScreen();
    }
    
    if (state == AppLifecycleState.resumed) {
      _checkForRecentCalls();
    }
  }
  
  Future<void> _checkForRecentCalls() async {
    try {
      final result = await _callEventChannel.invokeMethod('checkLastCall');
      if (result != null && result is Map) {
        final isRecent = result['isRecent'] == true;
        final number = result['number'] as String?;
        final duration = result['duration'] as int?;
        final type = result['type'] as String?;
        
        print('Recent call check - IsRecent: $isRecent, Number: $number, Duration: $duration, Type: $type');
        
        if (isRecent && number != null) {
          print('Recent call detected, showing call screen');
          _showCallScreen(
            callerName: _getContactName(number),
            callerNumber: number,
            callDuration: duration ?? 0,
            isIncoming: type == 'INCOMING',
          );
        }
      }
    } catch (e) {
      print('Error checking for recent calls: $e');
    }
  }
  
  Future<void> _handleCallEvent(MethodCall call) async {
    print('Received method call: ${call.method}');
    
    if (call.method == 'onCallEvent') {
      final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
      final String event = data['event'];
      final String number = data['number'];
      final int duration = data['duration'] ?? 0;
      
      print('Call Event: $event, Number: $number, Duration: $duration');
      print('Navigator key context available: ${navigatorKey.currentContext != null}');
      
      switch (event) {
        case 'INCOMING':
          print('Processing INCOMING call event');
          _showCallScreen(
            callerName: _getContactName(number),
            callerNumber: number,
            callDuration: 0,
            isIncoming: true,
          );
          break;
          
        case 'OUTGOING':
          print('Processing OUTGOING call event');
          _showCallScreen(
            callerName: _getContactName(number),
            callerNumber: number,
            callDuration: 0,
            isIncoming: false,
          );
          break;
          
        case 'CONNECTED':
          // Call is connected - update existing screen if needed
          print('Processing CONNECTED call event');
          break;
          
        case 'ENDED':
          print('Processing ENDED call event with duration: $duration');
          _showCallScreen(
            callerName: _getContactName(number),
            callerNumber: number,
            callDuration: duration,
            isIncoming: true, // This could be tracked separately
          );
          break;
          
        default:
          print('Unknown call event: $event');
      }
    } else if (call.method == 'onCallLogPermissionGranted') {
      print('Call log permission granted');
      // Permission granted, check for recent calls again
      await _checkForRecentCalls();
    } else if (call.method == 'onCallLogPermissionDenied') {
      print('Call log permission denied');
      // Handle permission denial - could show a dialog to user
    }
  }
  
  void _showCallScreen({
    String? callerName,
    String? callerNumber,
    int? callDuration,
    bool? isIncoming,
  }) {
    print('Attempting to show call screen - Context: ${navigatorKey.currentContext != null}');
    
    // Store the pending call screen data
    _pendingCallScreen = {
      'callerName': callerName,
      'callerNumber': callerNumber,
      'callDuration': callDuration,
      'isIncoming': isIncoming,
    };
    
    // Cancel any existing retry timer
    _pendingCallTimer?.cancel();
    
    // Try to show the screen immediately
    _tryShowCallScreen();
    
    // Set up a retry mechanism in case the app is in background
    _pendingCallTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_tryShowCallScreen()) {
        timer.cancel();
        _pendingCallTimer = null;
        _pendingCallScreen = null;
      }
    });
    
    // Timeout after 10 seconds
    Timer(const Duration(seconds: 10), () {
      _pendingCallTimer?.cancel();
      _pendingCallTimer = null;
      _pendingCallScreen = null;
    });
  }
  
  bool _tryShowCallScreen() {
    if (navigatorKey.currentContext == null) {
      print('Navigator context is null, retrying...');
      return false;
    }
    
    print('Navigator context available, showing call screen');
    
    // Cancel the retry timer
    _pendingCallTimer?.cancel();
    _pendingCallTimer = null;
    
    final data = _pendingCallScreen;
    if (data == null) {
      print('No pending call screen data');
      return false;
    }
    
    // Use WidgetsBinding.instance to ensure we're showing after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext == null) {
        print('Navigator context became null again');
        return;
      }
      
      // Push the CallScreen using GetX navigation
      Get.to(
        CallScreen(
          callerName: data['callerName'],
          callerNumber: data['callerNumber'],
          callDuration: data['callDuration'],
          isIncoming: data['isIncoming'],
          callStartTime: DateTime.now(),
        ),
      );
    });
    
    return true;
  }
  
  String _getContactName(String number) {
    // TODO: Implement contact lookup
    // For now, return the number or "Private Number" if empty
    return number.isNotEmpty ? number : 'Private Number';
  }
  
  void dispose() {
    _pendingCallTimer?.cancel();
    _callEventChannel.setMethodCallHandler(null);
  }

}