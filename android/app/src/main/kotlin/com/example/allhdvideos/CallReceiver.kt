package com.example.allhdvideos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class CallReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "CallReceiver"
        private var methodChannel: MethodChannel? = null
        
        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
        
        var lastCallState = TelephonyManager.CALL_STATE_IDLE
        var currentCallNumber: String? = null
        var callStartTime: Long = 0
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            
            Log.d(TAG, "Call state changed: $state, Number: $incomingNumber")
            
            when (state) {
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    // Incoming call is ringing
                    Log.d(TAG, "Incoming call from: $incomingNumber")
                    currentCallNumber = incomingNumber
                    lastCallState = TelephonyManager.CALL_STATE_RINGING
                    sendCallEventToFlutter("INCOMING", incomingNumber, 0)
                }
                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    // Call is connected (either incoming or outgoing)
                    Log.d(TAG, "Call connected")
                    if (lastCallState == TelephonyManager.CALL_STATE_IDLE) {
                        // This is an outgoing call
                        Log.d(TAG, "Outgoing call detected")
                        currentCallNumber = incomingNumber
                        sendCallEventToFlutter("OUTGOING", incomingNumber, 0)
                    }
                    callStartTime = System.currentTimeMillis()
                    lastCallState = TelephonyManager.CALL_STATE_OFFHOOK
                    sendCallEventToFlutter("CONNECTED", currentCallNumber, 0)
                }
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    // Call ended
                    Log.d(TAG, "Call ended")
                    if (lastCallState == TelephonyManager.CALL_STATE_OFFHOOK) {
                        val duration = ((System.currentTimeMillis() - callStartTime) / 1000).toInt()
                        Log.d(TAG, "Call duration: $duration seconds")
                        sendCallEventToFlutter("ENDED", currentCallNumber, duration)
                    }
                    lastCallState = TelephonyManager.CALL_STATE_IDLE
                    currentCallNumber = null
                }
            }
        }
    }
    
    private fun sendCallEventToFlutter(event: String, number: String?, duration: Int) {
        try {
            val eventData = mapOf(
                "event" to event,
                "number" to (number ?: "Unknown"),
                "duration" to duration
            )
            Log.d(TAG, "Sending call event to Flutter: $eventData")
            methodChannel?.invokeMethod("onCallEvent", eventData)
        } catch (e: Exception) {
            Log.e(TAG, "Error sending call event to Flutter", e)
        }
    }
}