package com.example.peckme;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.example.peckme/channel1";

    private MethodChannel flutterChannel; // ✅ Store reference

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        flutterChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);

        flutterChannel.setMethodCallHandler((call, result) -> {
            if ("callNativeMethod".equals(call.method)) {
                // ✅ Get arguments from Flutter
                String client_id = call.argument("client_id");
                String lead_id = call.argument("lead_id");
                String customerName = call.argument("customerName");
                String sessionId = call.argument("sessionId");
                String amzAppID = call.argument("amzAppID");
                String user_id = call.argument("user_id");
                String branch_id = call.argument("branch_id");
                String auth_id = call.argument("auth_id");
                String gpslat = call.argument("gpslat");
                String gpslong = call.argument("gpslong");
                String banID = call.argument("banID");
                String userMobile = call.argument("userMobile");
                String athena_lead_id = call.argument("athena_lead_id");
                String agentName = call.argument("agentName");
                String client_lead_id = call.argument("client_lead_id");

                System.out.println("------------------------");
                System.out.println("AuthID  :" + auth_id);
                System.out.println("BanId   :" + banID);
                System.out.println("session :" + sessionId);
                System.out.println("athena  :" + athena_lead_id);
                System.out.println("-----------------------");

                try {
                    switch (client_id) {
                        case "38":
                        case "28": {
                            String msg = startICICIApp(
                                    "com.servo.icici.oapnxt",
                                    "com.servo.icici.oapnxt.OPENOAPNXT",
                                    sessionId,
                                    auth_id,
                                    athena_lead_id
                            );
                            result.success(msg);
                            break;
                        }
                        case "11":  // ICICI SDK
                            try {
                                SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy HH:mm", Locale.getDefault());
                                String currentDate = sdf.format(new Date());
                                int parsedUserId = 0;
                                try {
                                    parsedUserId = Integer.parseInt(user_id);
                                } catch (NumberFormatException e) {
                                    parsedUserId = 0;
                                }
                                String agentVeerID = String.format("BIZ%05d", parsedUserId);

                                Class<?> iciciClass = Class.forName("com.bcpl.icici.IciciActivity"); // ⚠ confirm correct class name
                                Intent intent = new Intent(getApplicationContext(), iciciClass);

                                intent.putExtra("appId", athena_lead_id);
                                intent.putExtra("firstCallDate", currentDate);
                                intent.putExtra("appointmentDate", currentDate);
                                intent.putExtra("lastActionDate", currentDate);
                                intent.putExtra("customerName", customerName);
                                intent.putExtra("userName", auth_id);
                                intent.putExtra("AgentId", agentVeerID);
                                intent.putExtra("AgentName", agentName);
                                intent.putExtra("LeadId", lead_id);

                                if (intent.resolveActivity(getPackageManager()) != null) {
                                    startActivityForResult(intent, 11); // ✅ requestCode
                                    result.success("ICICI SDK Activity Started");
                                } else {
                                    result.error("ACTIVITY_NOT_FOUND", "ICICI Activity not installed/found!", null);
                                }
                            } catch (ClassNotFoundException e) {
                                result.error("CLASS_NOT_FOUND", "ICICI Activity class not found in SDK!", null);
                            } catch (Exception e) {
                                result.error("INTENT_ERROR", e.getMessage(), null);
                            }
                            break;
                        case "12":
                            result.success("Client Id " + client_id + "...");
                            break;
                        case "10":
                            result.success("GPS Lat Long ..." + gpslat + "," + gpslong);
                            break;
                        default:
                            result.success("Open ICICI APP ");
                            break;
                    }
                } catch (Exception e) {
                    result.error("NATIVE_ERROR", e.getMessage(), null);
                }
            } else {
                result.notImplemented();
            }
        });
    }

    // Modified onActivityResult to send SDK exit reliably
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == 11 || requestCode == 2 || requestCode == 6) {
            String response = "SDK closed";

            if (data != null) {
                if (data.hasExtra("cc_response")) {
                    response = data.getStringExtra("cc_response");
                } else if (data.hasExtra("response")) {
                    response = data.getStringExtra("response");
                }
            } else if (resultCode == RESULT_OK) {
                response = "Lead Completed"; // fallback
            }

            System.out.println("SDK Exit Response: " + response);

            if (flutterChannel != null) {
                flutterChannel.invokeMethod("onSdkExit", response);
            }
        }
    }


    // ✅ Utility function to start ICICI external app
    private String startICICIApp(
            String packageName,
            String action,
            String sessionValue,
            String agentName,
            String athena_lead_id
    ) {
        try {
            System.out.println("------------------------");
            System.out.println("BanId   :" + agentName);
            System.out.println("session :" + sessionValue);
            System.out.println("athena  :" + athena_lead_id);
            System.out.println("-----------------------");

            PackageManager pm = getPackageManager();
            pm.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES);
            Intent intent = new Intent();
            intent.setPackage(packageName);
            intent.setAction(action);

            Bundle bundle = new Bundle();
            bundle.putString("userName", agentName);
            bundle.putString("sessionId", sessionValue);
            bundle.putString("appId", athena_lead_id);
            bundle.putString("sourcing_application", "com.bizipac");
            intent.putExtras(bundle);

            startActivityForResult(intent, packageName.equals("com.servo.icici.oapnxt") ? 2 : 6);
            return "Opened ICICI app: " + packageName;

        } catch (PackageManager.NameNotFoundException e) {
            return "App not install (Please install it first)";
        } catch (ActivityNotFoundException ex) {
            return "ACTIVITY_NOT_FOUND: No matching activity found for " + packageName;
        } catch (Exception ex) {
            return "ERROR: " + ex.getMessage();
        }
    }
}
