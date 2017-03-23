package com.gide.mnodeclient;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.gide.mnodeclient.BaseHandler.NetBaseHandler;
import java.util.HashMap;
import java.util.Map;


public class MainActivity extends AppCompatActivity {
    private String TAG = "MainActivity";
    private Button getToken;
    private Button sendApi;
    // Used to load the 'native-lib' library on application startup.
    static {
        System.loadLibrary("native-lib");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        getToken = (Button) findViewById(R.id._main_getToken);
        getToken.setOnClickListener(mClickListener);
        sendApi = (Button)findViewById(R.id._main_base);
        sendApi.setOnClickListener(mClickListener);
    }

    View.OnClickListener mClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View view) {
            switch (view.getId()){
                case R.id._main_getToken:
                    try {
                        Login();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;
                case R.id._main_base:
                    try {
                        postHi();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;
                default:
                    break;
            }
        }
    };

    private void Login() throws Exception {
        Map param = new HashMap<String, String>();
        param.put("username","willyy");
        param.put("authcode","7788");
        NetBaseHandler.getHandler(this.getApplication()).getTokenByUserInfo(param, new Response.Listener() {
            @Override
            public void onResponse(Object response) {
                Log.i(TAG,response.toString());
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                Log.i(TAG,error.toString());
            }
        });
    }

    private void postHi() throws Exception {
        Map param = new HashMap<String, String>();
        param.put("username","willyy");
        param.put("authcode","7788");

        NetBaseHandler.getHandler(this.getApplication()).baseApi("post", "api/sayHello", param, new Response.Listener() {
            @Override
            public void onResponse(Object response) {
                Log.i(TAG,response.toString());
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {

            }
        });
    }

    /**
     * A native method that is implemented by the 'native-lib' native library,
     * which is packaged with this application.
     */
    public native String stringFromJNI();
}
