package com.gide.mnodeclient.BaseHandler;

import android.content.Context;
import android.util.Base64;
import android.util.Log;
import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.gide.mnodeclient.tools.GlobalUtil;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by willyy on 2017/3/17.
 */

public class NetBaseHandler {
    private String TAG = "NetBaseHandler";
    private static NetBaseHandler mHandler;
    private RequestQueue mRequestQueue;
    private static Context mCtx;
    private NetBaseHandler (Context context){
        mCtx = context;
        mRequestQueue = getRequestQueue();
    }

    public static synchronized NetBaseHandler getHandler(Context context){
        if (mHandler == null){
            mHandler = new NetBaseHandler(context);
        }
        return mHandler;
    }

    public RequestQueue getRequestQueue(){
        if (mRequestQueue == null){
            mRequestQueue = Volley.newRequestQueue(mCtx.getApplicationContext());
        }
        return mRequestQueue;
    }

    public void baseApi(String method, String url, final Map<String, String> param, final Response.Listener listener, final Response.ErrorListener error) throws Exception {

        final String jwt = CryptoWrapper.getWrapper(mCtx.getApplicationContext()).signatureJWT();
        final String URL = url;
        final String Med = method;
        url = GlobalUtil.ServerUrl+url;
        method = method.toUpperCase();

        if (method.equals("GET")){
            StringRequest stringRequest = new StringRequest(Request.Method.GET, url, new Response.Listener<String>() {
                @Override
                public void onResponse(String response) {
                    try {
                        JSONObject jsonResponse = new JSONObject(response);
                        if (jsonResponse.optInt("status") == 4000){

                            regainToken(new Response.Listener() {
                                @Override
                                public void onResponse(Object res) {
                                    try {
                                        JSONObject jsonRes = new JSONObject(res.toString());
                                        if (jsonRes.optInt("status")==1){
                                            baseApi(Med,URL,param,listener,error);
                                        }
                                    } catch (JSONException e) {
                                        e.printStackTrace();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                }
                            }, new Response.ErrorListener() {
                                @Override
                                public void onErrorResponse(VolleyError error) {

                                }
                            });
                        }
                        else{
                            listener.onResponse(response);
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }, error){
                @Override
                public Map<String, String> getHeaders() throws AuthFailureError {
                    Map<String,String> map = new HashMap<>();
                    map.put("JWT",jwt);
                    return map;
                }
            };
            mRequestQueue.add(stringRequest);
        }
        else if(method.equals("POST")){
            StringRequest stringRequest = new StringRequest(Request.Method.POST,url,new Response.Listener<String>() {
                @Override
                public void onResponse(String response) {
                    try {
                        JSONObject jsonResponse = new JSONObject(response);
                        if (jsonResponse.optInt("status") == 4000){

                            regainToken(new Response.Listener() {
                                @Override
                                public void onResponse(Object res) {
                                    try {
                                        JSONObject jsonRes = new JSONObject(res.toString());
                                        if (jsonRes.optInt("status")==1){
                                            baseApi(Med,URL,param,listener,error);
                                        }
                                    } catch (JSONException e) {
                                        e.printStackTrace();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                }
                            }, new Response.ErrorListener() {
                                @Override
                                public void onErrorResponse(VolleyError error) {

                                }
                            });
                        }
                        else{
                            listener.onResponse(response);
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            },error){
                @Override
                public Map<String, String> getHeaders() throws AuthFailureError {
                    Map<String,String> map = new HashMap<>();
                    map.put("JWT",jwt);
                    return map;
                }
                @Override
                protected Map<String, String> getParams() throws AuthFailureError {
                    return param;
                }
            };
            mRequestQueue.add(stringRequest);
        }
    }

    private void regainToken(final Response.Listener listener, Response.ErrorListener error) throws Exception {
        String rk = CryptoWrapper.getWrapper(mCtx.getApplicationContext()).getRK();
        HashMap m = GlobalUtil.getTokenPrefs(mCtx.getApplicationContext());
        JSONObject obj = new JSONObject();
        try {
            obj.put("userid",m.get(GlobalUtil.Userid));
            obj.put("accessKey",m.get(GlobalUtil.AccessKey));
            obj.put("rk",rk);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        byte[] jsonData = obj.toString().getBytes("UTF8");
        byte[] enData = CryptoWrapper.getWrapper(mCtx.getApplicationContext()).encryptData(jsonData);
        byte[] jsonByte = Base64.encode(enData,Base64.URL_SAFE|Base64.NO_WRAP);
        final String jsonStr = new String( jsonByte ,"UTF-8");

        final Map<String,String>param = new HashMap<String,String>(){
            {
                put("info",jsonStr);
            }
        };

        String url = "api/regainToken";
        url = GlobalUtil.ServerUrl+url;

        StringRequest stringRequest = new StringRequest(Request.Method.POST, url, new Response.Listener<String>() {
            @Override
            public void onResponse(String response) {
//                Log.i(TAG,response);
                try{
                    JSONObject jsonResponse = new JSONObject(response);
                    if (jsonResponse.optString("token")!=""){
                        String token = jsonResponse.optString("token").toString();
                        boolean verify = CryptoWrapper.getWrapper(mCtx.getApplicationContext()).verifyJwt(token);
                        if (verify) {
                            listener.onResponse("{\"status\":1}");
                        }
                        else{
                            listener.onResponse("{\"status\":0}");
                        }
                    }
                    else
                    {
                        listener.onResponse(response);
                    }
                }catch(Exception e){
                    e.printStackTrace();
                }

            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                Log.i(TAG,error.toString());
            }
        }){
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                return param;
            }
        };
        mRequestQueue.add(stringRequest);
    }

    public void getTokenByUserInfo(final Map<String,String>userinfo, final Response.Listener listener, Response.ErrorListener error) throws Exception {
        String username = userinfo.get("username") !=null ? userinfo.get("username"):"";
        String password = userinfo.get("password") !=null ? userinfo.get("password"):"";
        String authcode = userinfo.get("authcode") !=null ? userinfo.get("authcode"):"";
        String rk = CryptoWrapper.getWrapper(mCtx.getApplicationContext()).getRK();
        JSONObject obj = new JSONObject();
        try {
            obj.put("username",username);
            obj.put("password",password);
            obj.put("authcode",authcode);
            obj.put("rk",rk);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        byte[] jsonData = obj.toString().getBytes("UTF8");
        byte[] enData = CryptoWrapper.getWrapper(mCtx.getApplicationContext()).encryptData(jsonData);
        byte[] jsonByte = Base64.encode(enData,Base64.URL_SAFE|Base64.NO_WRAP);
        final String jsonStr = new String( jsonByte ,"UTF-8");

        final Map<String,String>param = new HashMap<String,String>(){
            {
                put("info",jsonStr);
            }
        };

        String url = "api/getToken";
        url = GlobalUtil.ServerUrl+url;

        StringRequest stringRequest = new StringRequest(Request.Method.POST, url, new Response.Listener<String>() {
            @Override
            public void onResponse(String response) {
                try{
                    JSONObject jsonResponse = new JSONObject(response);
                    if (jsonResponse.optString("token")!=""){
                        String token = jsonResponse.optString("token").toString();
                        boolean verify = CryptoWrapper.getWrapper(mCtx.getApplicationContext()).verifyJwt(token);
                        if (verify) {
                            listener.onResponse("{\"status\":1}");
                        }
                        else{
                            listener.onResponse("{\"status\":0}");
                        }
                    }
                    else
                    {
                        listener.onResponse(response);
                    }
                }catch(Exception e){
                    e.printStackTrace();
                }

            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                Log.i(TAG,error.toString());
            }
        }){
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                return param;
            }
        };
        mRequestQueue.add(stringRequest);
    }
}
