package com.gide.mnodeclient.tools;

import android.content.Context;
import android.content.SharedPreferences;
import java.util.HashMap;

/**
 * Created by willyy on 2017/1/23.
 */
public class GlobalUtil {
    public static final boolean SSL_ON = false;
    public static final String CryptLicense = "1276121866@qq.com";
    public static final String ServerUrl = "http://10.10.252.10:8880/";

    public static final String UserPref = "userPref";
    public static final String Userid = "userid";
    public static final String AccessKey = "ak";


    private static GlobalUtil ourInstance = new GlobalUtil();
    public static GlobalUtil getInstance() {
        return ourInstance;
    }

    private GlobalUtil() {
    }

    public static HashMap<String,Object> getTokenPrefs(Context context)
    {
        SharedPreferences preferences = context.getSharedPreferences(UserPref,context.MODE_PRIVATE);
        String userid = preferences.getString(Userid,"");
        String ak = preferences.getString(AccessKey,"");
        HashMap<String,Object>devPref = new HashMap<String,Object>();
        devPref.put(Userid,userid);
        devPref.put(AccessKey,ak);

        return devPref;
    }
    public static void setTokenPrefs(Context context, HashMap<String,String>prefsMap){
        SharedPreferences preferences = context.getSharedPreferences(UserPref,context.MODE_PRIVATE);
        SharedPreferences.Editor prefEditor = preferences.edit();
        for (String key : prefsMap.keySet()){
            Object obj = prefsMap.get(key);
            switch (key)
            {
                case Userid:
                    String userid = (String)obj;
                    prefEditor.putString(Userid,userid);
                    break;
                case AccessKey:
                    String ak = (String)obj;
                    prefEditor.putString(AccessKey,ak);
                    break;
                default:
                    break;
            }
        }
        prefEditor.commit();
    }
}
