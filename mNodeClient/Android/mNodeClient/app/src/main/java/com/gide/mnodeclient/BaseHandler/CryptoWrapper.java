package com.gide.mnodeclient.BaseHandler;

import android.content.Context;
import android.util.Base64;
import com.gide.mnodeclient.R;
import com.gide.mnodeclient.tools.GlobalUtil;
import org.json.JSONException;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.X509EncodedKeySpec;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;

/**
 * Created by willyy on 2017/3/21.
 */

public class CryptoWrapper {
    private String TAG = "CryptoWarpper";
    private static CryptoWrapper mWrapper;
    private static Context mCtx;
    private static String AESKey;
    private static PublicKey publicKey;
    private static String AccessKey = "";
    private static String UserID = "";
    private static int exKeyLife = 20;
    private CryptoWrapper (Context context){
        mCtx = context;

    }
    public static synchronized CryptoWrapper getWrapper(Context context) throws Exception {
        if (mWrapper == null){
            mWrapper = new CryptoWrapper(context);

            HashMap m = GlobalUtil.getTokenPrefs(mCtx.getApplicationContext());
            UserID = (String) m.get(GlobalUtil.Userid);
            AccessKey = (String) m.get(GlobalUtil.AccessKey);
            InputStream p = mCtx.getApplicationContext().getResources().openRawResource(R.raw.p);
            publicKey = loadPublicKey(p);
        }
        return mWrapper;
    }

    /**
     * pub method
     */
    public String signatureJWT() throws UnsupportedEncodingException {
        return signatureJwtWithAccessKey();
    }

    private String signatureJwtWithAccessKey() throws UnsupportedEncodingException {
        JSONObject jwtPayloadJson = new JSONObject();
        try {
            jwtPayloadJson.put("iss", UserID);
            jwtPayloadJson.put("exp", new Date().getTime()+exKeyLife);
            jwtPayloadJson.put("iat", new Date().getTime());
        } catch (JSONException e) {
            // Will never happen.
        }
        String jwtPayloadStr = jwtPayloadJson.toString();
        Map<String, Object> header = new HashMap<String, Object>();
        header.put("typ", "JWT");
        String jwtStr = Jwts.builder()
                .setHeader(header)
                .setPayload(jwtPayloadStr)
                .signWith(SignatureAlgorithm.HS256, AccessKey.getBytes("UTF-8"))
                .compact();
        return jwtStr;
    }

    /**
     * JWT
     */
    public boolean verifyJwt(String jwtStr) throws Exception {
        boolean retVal = false;

        String enToken = verifyJWTwithPublicKey(jwtStr);
        String deStr = decrypt(enToken);
        JSONObject obj = new JSONObject(deStr);
        final String userid = (String)obj.get("userid");
        final String accessKey = (String)obj.get("accessKey");
        if (userid!=null && accessKey!=null){
            final HashMap param = new HashMap() {
                {
                    put(GlobalUtil.Userid,userid);
                    put(GlobalUtil.AccessKey,accessKey);
                }
            };
            GlobalUtil.setTokenPrefs(mCtx.getApplicationContext(),param);
        }
        HashMap m = GlobalUtil.getTokenPrefs(mCtx.getApplicationContext());
        UserID = (String) m.get(GlobalUtil.Userid);
        AccessKey = (String) m.get(GlobalUtil.AccessKey);
        if (UserID!=null && AccessKey !=null){
            retVal = true;
        }
        return retVal;
    }

    public String decrypt(String sSrc) throws Exception {
        String sKey = AESKey.substring(0,32);
        String ivParameter = AESKey.substring(32,48);
        try {
            byte[] raw = sKey.getBytes();
            SecretKeySpec skeySpec = new SecretKeySpec(raw, "AES");
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            IvParameterSpec iv = new IvParameterSpec(ivParameter.getBytes());
            cipher.init(Cipher.DECRYPT_MODE, skeySpec, iv);

            byte[] encrypted1 = Base64.decode(sSrc,Base64.NO_WRAP);
            byte[] original = cipher.doFinal(encrypted1);
            String originalString = new String(original, "UTF8");
            return originalString;
        } catch (Exception ex) {
            return null;
        }
    }

    public String verifyJWTwithPublicKey(String jwtStr){
        Claims claims = Jwts.parser().setSigningKey(publicKey).parseClaimsJws(jwtStr).getBody();
        String enToken = (String)claims.get("token");
        return enToken;
    }

    /**
     * crypto
     */
    public String getRK(){
        AESKey = getRandomKey();
        return AESKey;
    }

    private String getRandomKey(){
        int kNumber = 48;
        String sourceString = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        StringBuilder resultString = new StringBuilder();
        Random r = new Random();
        for (int i = 0;i<kNumber;i++){
            int l = r.nextInt()%36;
            if (l<0){
                l = 0-l;
            }
            resultString.append(sourceString.substring(l,l+1));
        }
        return resultString.toString();
    }

    private static PublicKey loadPublicKey(InputStream in) throws Exception
    {
        try
        {
            return loadPublicKey(readKey(in));
        }
        catch (IOException e)
        {
            throw new Exception("IOException");
        }
        catch (NullPointerException e)
        {
            throw new Exception("NullPointerException");
        }
    }

    private static PublicKey loadPublicKey(String publicKeyStr) throws Exception
    {
        try
        {
            byte[] buffer = Base64.decode(publicKeyStr,Base64.NO_WRAP);
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            X509EncodedKeySpec keySpec = new X509EncodedKeySpec(buffer);
            return (RSAPublicKey) keyFactory.generatePublic(keySpec);
        }
            catch (NoSuchAlgorithmException e)
        {
            throw new Exception("NoSuchAlgorithmException");
        }
            catch (InvalidKeySpecException e)
        {
            throw new Exception("InvalidKeySpecException");
        }
            catch (NullPointerException e)
        {
            throw new Exception("NullPointerException");
        }
    }

    private static String readKey(InputStream in) throws IOException
    {
        BufferedReader br = new BufferedReader(new InputStreamReader(in));
        String readLine = null;
        StringBuilder sb = new StringBuilder();
        while ((readLine = br.readLine()) != null)
        {
            if (readLine.charAt(0) == '-')
            {
                continue;
            }
            else
            {
                sb.append(readLine);
                sb.append('\n');
            }
        }

        return sb.toString();
    }

    public byte[] encryptData(byte[] data)
    {
        try
        {
            Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
            // 编码前设定编码方式及密钥
            cipher.init(Cipher.ENCRYPT_MODE, publicKey);
            // 传入编码数据并返回编码结果
            return cipher.doFinal(data);
        }
        catch (Exception e)
        {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * 用私钥解密
     *
     * @param encryptedData
     *            经过encryptedData()加密返回的byte数据
     * @return
     */
    public byte[] decryptData(byte[] encryptedData,PrivateKey privateKey)
    {
        try
        {
            Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
            cipher.init(Cipher.DECRYPT_MODE, privateKey);
            return cipher.doFinal(encryptedData);
        }
        catch (Exception e)
        {
            return null;
        }
    }
}

