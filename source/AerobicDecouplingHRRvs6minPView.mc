using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System as Sys;
using Toybox.UserProfile as User;

class AerobicDecouplingHRRvs6minPView extends WatchUi.SimpleDataField {
    protected var heartRate = 0.0f;
    protected var power = 0.0f;
    protected var rollingAVGheartRate = 0;
    protected var rollingAVGheartRateSum = 0;
    protected var rollingAVGpower = 0;
    protected var rollingAVGpowerSum = 0;
    protected var arrayHRValue = new [180]; // TODO: Make size configurable
    protected var arrayPowerValue = new [180];
    protected var avgHRValue = 0;
    protected var avgPowerValue = 0;
    protected var userRestHR = 0;
    protected var userMaxHR = 0;
    protected var userpercentHRR = 0;

    protected var userSixMinMMP;

    protected var curPos = 0;
    protected var recCycleCount = 0;
    var decouplingFactor;

    function initialize() {
        SimpleDataField.initialize();
        label = "%HRR/%6mMMP";

        for (var i = 0; i < arrayHRValue.size(); ++i) {
            arrayHRValue[i] = 0;
            arrayPowerValue[i] = 0;
        }

        readHRPowerSettings();

//        userRestHR = 45;
//        userMaxHR = 202;
//        userSixMinMMP = 380;
    }

    function compute(info) {
        if (info has :currentHeartRate && info has :currentPower) {
            if (info.currentHeartRate != null ) { // && info.elapsedTime != null && info.elapsedTime > 0) {
                heartRate = info.currentHeartRate;
            } else {
                heartRate = 0.0f;
            }
            if (info.currentPower != null ) { // && info.elapsedTime != null && info.elapsedTime > 0) {
                power = info.currentPower;
            } else {
                power = 0.0f;
            }
        }

        avgHRValue = avgHRValue + heartRate;
        avgPowerValue = avgPowerValue + power;
        recCycleCount = recCycleCount + 1;
        if (recCycleCount > 3 && avgHRValue > 0) {
            arrayHRValue[curPos] = (avgHRValue / recCycleCount).toNumber();
            arrayPowerValue[curPos] = (avgPowerValue / recCycleCount).toNumber();
            for (var i = 0; i < curPos; ++i) {
                rollingAVGheartRateSum = rollingAVGheartRateSum + arrayHRValue[i];
                rollingAVGpowerSum = rollingAVGpowerSum + arrayPowerValue[i];
            }
            if (curPos == 0) {
                rollingAVGheartRate = heartRate;
                rollingAVGpower = power;
            }
            else {
                rollingAVGheartRate = (rollingAVGheartRateSum / curPos).toNumber();
                rollingAVGpower = (rollingAVGpowerSum / curPos).toNumber();
            }
            userpercentHRR = (rollingAVGheartRate.toFloat() - userRestHR) * 100 / (userMaxHR - userRestHR);

            if ( userSixMinMMP > 0 ) {
                Sys.println("" + curPos + " currentHR: " + heartRate + ", rolling avg:" + rollingAVGheartRate + ", currentPWR: " + power + ", rolling avg:" + rollingAVGpower
                     + ", elapsedTime:" + info.elapsedTime
                     + ", %HRR: " + userpercentHRR.format("%.4f") + ", %6minP: " + (rollingAVGpower.toFloat() * 100 / userSixMinMMP).format("%.4f"));
            }

            curPos = curPos + 1;
            if (curPos > arrayHRValue.size()-1) {
                curPos = 0;
            }

            recCycleCount = 0;
            avgHRValue = 0;
            avgPowerValue = 0;
            rollingAVGheartRateSum = 0;
            rollingAVGpowerSum = 0;
        }

        if ( rollingAVGheartRate != null && rollingAVGheartRate > 0 && rollingAVGpower > 0 && userpercentHRR > 0 && userSixMinMMP > 0 ) {
            decouplingFactor = userpercentHRR / (rollingAVGpower.toFloat() * 100 / userSixMinMMP);
            Sys.println("Decoupling factor: " + decouplingFactor.format("%.4f"));
            return decouplingFactor.format("%.2f");
        }
        if ( userSixMinMMP == 0 ) {
            return "6minP?";
        }
        return "n/a";
    }

    function readHRPowerSettings() {
		// TODO: Read flag whether to use MPP oder sixMinPace

        var customHREnabled = coalesce(Application.getApp().getProperty("UseCustomHR"),false);
        var customRestHR = coalesce(Application.getApp().getProperty("restingHR"),0);
        var customMaxHR = coalesce(Application.getApp().getProperty("maxHR"),0);
        userSixMinMMP = coalesce(Application.getApp().getProperty("sixMinMMP"),0);
        if (customHREnabled && customRestHR > 0 && customMaxHR > customRestHR) {
            userRestHR = customRestHR;
            userMaxHR = customMaxHR;
            System.println("Using custom HR from data field settings: " + userRestHR + "--" + userMaxHR);
        }
        else {
            var zones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
            userMaxHR = coalesce(zones[zones.size()-1],-1);
            userRestHR = coalesce(UserProfile.getProfile().restingHeartRate,0);
            System.println("Using HR from user profile: " + userRestHR + "--" + userMaxHR);
        }
    }

//    // Get the field layout
//    function onLayout(dc) {
//        View.setLayout(Rez.Layouts.MainLayout(dc));
//    }

//    function onUpdate(dc) {
//        View.findDrawableById("Background").setColor(getBackgroundColor());
//        var value = View.findDrawableById("value");
//        value.setColor(Graphics.COLOR_BLACK);
//        value.setText(heartRate.format("%.2f"));
//        View.onUpdate(dc);
//    }

    function coalesce(nullableValue, defaultValue) {
        if (nullableValue != null) {
           return nullableValue;
        } else {
           return defaultValue;
        }
    }

}