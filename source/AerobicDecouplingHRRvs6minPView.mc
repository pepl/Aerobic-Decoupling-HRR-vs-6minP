using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System as Sys;
using Toybox.UserProfile as User;

class AerobicDecouplingHRRvs6minPView extends WatchUi.SimpleDataField {
    protected var heartRate = 0.0f;
    protected var power_or_pace = 0.0f;
    protected var rollingAVGheartRate = 0;
    protected var rollingAVGheartRateSum = 0;
    protected var rollingAVGpowerOrPace = 0;
    protected var rollingAVGpowerOrPaceSum = 0;
    protected var arrayHRValue = new [180]; // TODO: Make size configurable
    protected var arrayPowerOrPaceValue = new [180];
    protected var avgHRValue = 0;
    protected var avgPowerOrPaceValue = 0;
    protected var userRestHR = 0;
    protected var userMaxHR = 0;
    protected var userpercentHRR = 0;
    protected var userpercentP = 0;

    protected var userSixMinP;
    protected var userPisMMP = 1;

    protected var curPos = 0;
    protected var recCycleCount = 0;
    var decouplingFactor;

    function initialize() {
        SimpleDataField.initialize();

        for (var i = 0; i < arrayHRValue.size(); ++i) {
            arrayHRValue[i] = 0;
            arrayPowerOrPaceValue[i] = 0;
        }

        readHRPowerSettings();

        /*
        userPisMMP = 0;
        userRestHR = 49;
        userMaxHR = 202;
        userSixMinP = 455; // 455 // 380
        */

        if ( userPisMMP == 1 ) {
            label = "%HRR/%6mMMP";
        }
        else {
            label = "%HRR/%6mPace";
        }
    }

    function compute(info) {
        if (info has :currentHeartRate && (info has :currentPower || info has :currentSpeed)) {
            if (info.currentHeartRate != null ) { // && info.elapsedTime != null && info.elapsedTime > 0) {
                heartRate = info.currentHeartRate;
            } else {
                heartRate = 0.0f;
            }
            if (userPisMMP == 1) {
                if (info.currentPower != null ) { // && info.elapsedTime != null && info.elapsedTime > 0) {
                    power_or_pace = info.currentPower;
                } else {
                    power_or_pace = 0.0f;
                }
            }
            else {
                if (info.currentSpeed != null && info.currentSpeed > 0) { // && info.elapsedTime != null && info.elapsedTime > 0) {
                    // currentSpeed => m/s
                    // pace => s/km
                    power_or_pace = 1000 / info.currentSpeed;
                    // Sys.println("currentSpeed: " + info.currentSpeed + ", km/h: " + (info.currentSpeed * 10000 / 3600) + ", pace (min/km): " + (power_or_pace / 60) + ", pace (s/km): " + power_or_pace);
                } else {
                    power_or_pace = 0.0f;
                }
            }
        }

        avgHRValue = avgHRValue + heartRate;
        avgPowerOrPaceValue = avgPowerOrPaceValue + power_or_pace;
        recCycleCount = recCycleCount + 1;
        if (recCycleCount > 3 && avgHRValue > 0) {
            arrayHRValue[curPos] = (avgHRValue / recCycleCount).toNumber();
            arrayPowerOrPaceValue[curPos] = (avgPowerOrPaceValue / recCycleCount).toNumber();
            for (var i = 0; i < curPos; ++i) {
                rollingAVGheartRateSum = rollingAVGheartRateSum + arrayHRValue[i];
                rollingAVGpowerOrPaceSum = rollingAVGpowerOrPaceSum + arrayPowerOrPaceValue[i];
            }
            if (curPos == 0) {
                rollingAVGheartRate = heartRate;
                rollingAVGpowerOrPace = power_or_pace;
            }
            else {
                rollingAVGheartRate = rollingAVGheartRateSum / curPos;
                rollingAVGpowerOrPace = rollingAVGpowerOrPaceSum / curPos;
            }

            userpercentHRR = (rollingAVGheartRate.toFloat() - userRestHR) * 100 / (userMaxHR - userRestHR);
            if ( userSixMinP > 0 ) {
                if ( userPisMMP == 1 ) {
                    userpercentP = (rollingAVGpowerOrPace.toFloat() * 100 / userSixMinP);
                }
                else if ( rollingAVGpowerOrPace > 0 )  {
                    userpercentP = (userSixMinP * 100 / rollingAVGpowerOrPace.toFloat());
                }

                Sys.println("" + curPos + " currentHR: " + heartRate + ", rolling avg:" + rollingAVGheartRate + ", currentP: " + power_or_pace + ", rolling avg:" + rollingAVGpowerOrPace
                     + ", elapsedTime:" + info.elapsedTime
                     + ", %HRR: " + userpercentHRR.format("%.4f") + ", %6minP: " + userpercentP.format("%.4f"));
            }

            curPos = curPos + 1;
            if (curPos > arrayHRValue.size()-1) {
                curPos = 0;
            }

            recCycleCount = 0;
            avgHRValue = 0;
            avgPowerOrPaceValue = 0;
            rollingAVGheartRateSum = 0;
            rollingAVGpowerOrPaceSum = 0;
        }

        if ( rollingAVGheartRate != null && rollingAVGheartRate > 0 && rollingAVGpowerOrPace > 0 && userpercentHRR > 0 && userSixMinP > 0 ) {
            decouplingFactor = userpercentHRR / userpercentP;
            Sys.println("Decoupling factor: " + decouplingFactor.format("%.4f"));
            return decouplingFactor.format("%.2f");
        }
        if ( userSixMinP == 0 ) {
            return "6minP? Configure via Connect App!";
        }
        return "n/a";
    }

    function readHRPowerSettings() {
        var customHREnabled = coalesce(Application.getApp().getProperty("UseCustomHR"),false);
        var customRestHR = coalesce(Application.getApp().getProperty("restingHR"),0);
        var customMaxHR = coalesce(Application.getApp().getProperty("maxHR"),0);
        userSixMinP = coalesce(Application.getApp().getProperty("sixMinMMP"),0);
        if ( userSixMinP == null || userSixMinP == 0 ) {
            userSixMinP = coalesce(Application.getApp().getProperty("sixMinPace"),0);
            if ( userSixMinP > 0 ) {
                userSixMinP = userSixMinP;
                userPisMMP = 0;
                System.println("Using 6min Pace from settings");
            }
        }
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

    function coalesce(nullableValue, defaultValue) {
        if (nullableValue != null) {
           return nullableValue;
        } else {
           return defaultValue;
        }
    }

}