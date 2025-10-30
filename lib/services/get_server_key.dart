import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  final scopes = [
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/firebase.database',
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  Future<String> getServerKeyToken() async {
    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "bizipac-6bb00",
        "private_key_id": "b94e15ccd4ba7fbbd9b9bc7738c3f041d8b07fc5",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDeKiyql2muJ161\nMrqOwBpJUhU0tb9MJtbA29qHNIaU5wReVCABWbjXULqRjFG9CJZd0yDzRs2L1eEa\nVty8kVbX98mTJcsIECdsNUjZ2pWM0PuKVufYqql+QdLhiNS9sXcnJ5wBP9sbnrHB\nimdf+64zRcRfYWsda/3U7OvZgHShMzBm4M4qDsoXYt2K6v73zm6knxT5p3HuuIOJ\nk1glokA2+iQ8Ti9fsgyKB5HzzJT0LHHsLpw5BoPWx/xb4lLxMBwq3fPC6g8WsjJq\nxD9bhZuOjvrwRbSN08bqNh9944qqS1mAfmJGGZPsfuTnygUISKd9huiBnJENv/Q1\nlGASrFqxAgMBAAECggEAHHLxn9G+VHERsWni1mNWqmNyuDp62e1STEWLBQvOnRQ9\nLLgglhOvdhEOJxO9JtQJ709ZNZXwPdMgXX9YimQhJwxBuZBaILjy12o2X0Fcq7ja\nMTOiQk5OYI7cyok7VuQ6Eh9CHK3Y6L9IW3SV+sZPnxy0whMHRK/+w+yn4gUPSlH2\n6D4EWjeLv9H6NWNFPHjS4dNfgYuHF6rNcNIQWwc5bbD6DyyV1TAE74O36fpaZb6G\nbjXo9L7lJdRFpb6hSPDVI9j0hhTEXLY9ON97no8IyNlqyiBazkIKfD3+G4exZCa2\nmhovXmRLSnSo1WBL5GtVF/UuVXXz5TtoxCAlmPwZnQKBgQD21FwhAuX04QdLnCWk\n8BYIKRIausvmxkNyWbtwrsYlqss3CUwnQZ0AIU4kFRcDgd7iMOJnCse2oPA/7Nja\nMsEBiEzEyMxT8pODaHPctqlwlSSXDvuAb2p4dazM4n4wtA3PbY+s2uNsPZU5RWof\nWjwxsMC3sX0lM6imehJMiSS9dQKBgQDmazku0dtzt4lhCdI+XOrGagiOQz/KuR6j\nLzuvo3hNbm/VBw/hZjD8l2/gtnk4GKklN/NtaxNUG+Dbij77pLkPML6zLI+6OgLh\nhVLo6FS32MrsrObiMDceke2Sd5cDzqCYLiIxeE7lZbgZhmnVWn2N+S4cLCc4M9NT\nJVpp87WUzQKBgQDkDBQKk+juNLJO0zecig1xALEvbQJSdz99eRZK588+oewbL0Xi\nxyZNJnhRsgKPRQAuL0geN8GJJGyUQzmfb2EPD2UOMw9FSEuuD2VsuH8X+1PRFRCc\n+1N9dAtxSJmaWeCgkvM5mwqfyM4EGfQQf4g5yLplfWDIbFAXb5VUjSkauQKBgFDO\nE2ym7cXj/IqKTi/OmArjDoMNdGacivEBVHYg5sSI0TEs29XY5579YJ+2fkY857yE\npZqerVWWvUFgdvv65Wc9WfMt0m2lgHMkNVI2f9dFcMyVShbSf9H5rQ3rYItWQB1+\nOEGPBmQOSwSwjZbjuBo8432/wjVEf3yuIcn8TJaVAoGBAOV37rgCbooQfv+nnb1l\nRFZmLvz80JRy0lGvwUJ+ElpyPWsWbdizoJjOXlBpb5b4u+P3thzzT5oiTbmc1oFS\nI85qYW0bL699s63Vx+OY9Hf3+TEdp7H0++iUB8iQXtzP3bjpE/Gx5ahKRgUBMBhy\niJywlHxGcwUP85ymj61YwIL2\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-fbsvc@bizipac-6bb00.iam.gserviceaccount.com",
        "client_id": "107313937605053262267",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40bizipac-6bb00.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      }),
      scopes,
    );
    final accessServerKey = client.credentials.accessToken.data;
    return accessServerKey;
  }
}
