using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System as Sys;
using Toybox.UserProfile as User;
using Toybox.FitContributor;
using Toybox.Application.Properties;

class AerobicDecouplingHRRvs6minPView extends WatchUi.SimpleDataField {
    protected var heartRate = 0.0f;
    protected var power_or_pace = 0.0f;
    protected var rollingAVGheartRate = 0;
    protected var rollingAVGheartRateSum = 0;
    protected var rollingAVGpowerOrPace = 0;
    protected var rollingAVGpowerOrPaceSum = 0;
    protected var arrayHRValue = [];
    protected var arrayPowerOrPaceValue = [];
    protected var avgHRValue = 0;
    protected var avgPowerOrPaceValue = 0;
    protected var userRestHR = 0;
    protected var userMaxHR = 0;
    protected var userpercentHRR = 0;
    protected var userpercentP = 0;

    const DEFAULT_ROLLING_WINDOW_SIZE = 540;
    protected var rollingWindowSize;
    protected var userSixMinP;
    protected var userPisMMP = 1;

    protected var curPos = 0;

    protected var recordToFIT = null;
    var decouplingFactor;
    var decouplingFactorField = null;
    const DECOUPLING_FIELD_ID = 0;

    function initialize() {
        SimpleDataField.initialize();

        readSettings();

        /*
        recordToFIT = true;
        userPisMMP = 1;
        userRestHR = 49;
        userMaxHR = 202;
        userSixMinP = 380; // 455 // 380
        */

        if ( userPisMMP == 1 ) {
            label = "%HRR/%6mMMP";
        }
        else {
            label = "%HRR/%6mPace";
        }

        if ( recordToFIT != null ) {
            decouplingFactorField = createField(
                "AerobicDecouplingFactor",
                DECOUPLING_FIELD_ID,
                FitContributor.DATA_TYPE_FLOAT,
                {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=> label }
            );
            decouplingFactorField.setData(0.0);
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
        if (avgHRValue > 0 && avgPowerOrPaceValue > 0 && power_or_pace > 0) {
            arrayHRValue.add(avgHRValue);
            arrayPowerOrPaceValue.add(avgPowerOrPaceValue);
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
            if ( userSixMinP instanceof Lang.Number && userSixMinP > 0 ) {
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
            if (curPos > rollingWindowSize) {
                curPos = 0;
                arrayHRValue = [];
                arrayPowerOrPaceValue = [];
            }

            avgHRValue = 0;
            avgPowerOrPaceValue = 0;
            rollingAVGheartRateSum = 0;
            rollingAVGpowerOrPaceSum = 0;
        }

        if ( rollingAVGheartRate != null && rollingAVGheartRate > 0 && rollingAVGpowerOrPace > 0 && userpercentHRR > 0 && userSixMinP instanceof Lang.Number && userSixMinP > 0 ) {
            decouplingFactor = userpercentHRR / userpercentP;
            Sys.println("Decoupling factor: " + decouplingFactor.format("%.4f"));
            if ( recordToFIT != null ) {
                decouplingFactorField.setData(decouplingFactor);
            }
            return decouplingFactor.format("%.2f");
        }
        if ( userSixMinP instanceof Lang.Number && userSixMinP == 0 ) {
            return "6minP? Configure via Connect App!";
        }
        return "n/a";
    }

    function readSettings() {
        var customHREnabled;
        var customRestHR;
        var customMaxHR;
        var userSixMinPace;
        var customRollingWindowSize;

		if ( Toybox.Application has :Storage ) {
			customHREnabled = coalesce(Properties.getValue("UseCustomHR"),false);
			customRestHR = coalesce(Properties.getValue("restingHR"),0);
			customMaxHR = coalesce(Properties.getValue("maxHR"),0);
			userSixMinP = coalesce(Properties.getValue("sixMinMMP"),0);
			userSixMinPace = coalesce(Properties.getValue("sixMinPace"),0);
			customRollingWindowSize = coalesce(Properties.getValue("rollingWindowSize"),DEFAULT_ROLLING_WINDOW_SIZE);
			recordToFIT = Properties.getValue("recordToFIT");
		} else {
			customHREnabled = coalesce(Application.getApp().getProperty("UseCustomHR"),false);
			customRestHR = coalesce(Application.getApp().getProperty("restingHR"),0);
			customMaxHR = coalesce(Application.getApp().getProperty("maxHR"),0);
			userSixMinP = coalesce(Application.getApp().getProperty("sixMinMMP"),0);
			userSixMinPace = coalesce(Application.getApp().getProperty("sixMinPace"),0);
			customRollingWindowSize = coalesce(Application.getApp().getProperty("rollingWindowSize"),DEFAULT_ROLLING_WINDOW_SIZE);
			recordToFIT = Application.getApp().getProperty("recordToFIT");
		}

        if ( userSixMinP == null || userSixMinP == 0 ) {
            userSixMinP = userSixMinPace;
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

        rollingWindowSize = customRollingWindowSize;
        if ( rollingWindowSize != DEFAULT_ROLLING_WINDOW_SIZE ) {
            System.println("Using custom rolling window size: " + rollingWindowSize);
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