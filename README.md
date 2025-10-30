=======API URL===========
BASE_URL="https://fms.bizipac.com/apinew/ws_new/";

#THIS IS USER AUTH URL
POST METHOD
'https://fms.bizipac.com/ws/userverification.php?mobile=6393539704&password=12345678'
RETURN OTP=1234

AFTER OTP ENTER THE THEN LOGIN USER AND FULL AUTHORISE
'https://fms.bizipac.com/ws/userauth.php?mobile=6393539704&password=123455674&userToken=DFDFGDFGD&teamho=1234&imeiNumber=GFRR34DF?'

IF YOU ARE SHOW THE ALL LEAD'S TO HIT THIS API
'https://fms.bizipac.com/apinew/ws_new/new_lead.php?uid=$uid&start=$start&end=$end&branch_id=$branchId&app_version=$app_version&app_type=$appType'

IF YOU ARE SHOW THE LEAD DETAILS BY LEAD TO HIT THIS API
"https://fms.bizipac.com/apinew/ws_new/new_lead_detail.php?lead_id=$leadId"

FETCH THE CHILD EXECUTIVE TO HIT THIS API
https://fms.bizipac.com/apinew/ws_new/childlist.php?parentid=$parentId //PARENTID IT MEANS USER ID

IF YOU ARE REFIX LEAD'S TO HIT THIS URL
"https://fms.bizipac.com/apinew/ws_new/refixlead.php?loginid=$loginId&leadid=$leadId&newdate=$newDate&location=$location&reason=$reason&newtime=$newTime&remark=$remark"

IF YOU ARE POSTPONED LEAD'S TO HIT THIS API
final uri = Uri.parse("https://fms.bizipac.com/apinew/ws_new/postponedlead.php");
final response = await http.post(
uri,
body: {
"loginid": loginId,
"leadid": leadId,
"remark": remark,
"location": location,
"reason": reason,
"newdate": newDate,
"newtime": newTime,
},
);

IF YOU ARE SINGLE LEAD'S TRANSER TO HIT THIS API
'https://fms.bizipac.com/apinew/ws_new/todaystransfered.php?uid=$uid'

IF YOU ARE MULTIPLE LEAD'S TRANSFER TO HIT THIS API
"https://fms.bizipac.com/apinew/ws_new/multipleLeadTransfer.php?leaddata=$payload""

IF ARE CHECK THE COMPLETED LEAD COUNT TO THE USER
'https://fms.bizipac.com/apinew/ws_new/today_completed_lead.php?uid=$uid&branch_id=$branchId'

THIS API USED TO FORGOT PASSWORD AND USER ENTER THE MOBILE NO EXIST OUR DATABASE MATCHING AND SEND
THE USER MOBILE NUMBER ON OTP
'https://fms.bizipac.com/apinew/ws_new/forgotPassword.php'

AFTER OTP PUT AND NEW PASSWORD ENTER THEN SUCCESSFULLY MESSAGE
'https://fms.bizipac.com/apinew/ws_new/userForgotPassword.php?'

ALL THE DOCUMENT HERE THIS API
"https://fms.bizipac.com/apinew/display/document.php"

IF YOU ARE CALLING FUCTION THEN THIS API GET A LEADID AND CALL
""https://fms.bizipac.com/apinew/ws_new/exotel_getnumber.php?lead_id=$leadId""

THIS API STORE THE DOCUMENT IN MYSQL DATABASE
""https://fms.bizipac.com/apinew/ws_new/add_doc_simple.php""

IF YOU ARE FETCH THE TIME_SLOT TO HIT THIS API
"https://fms.bizipac.com/apinew/ws_new/time_slot.php"

IF YOU ARE FETCH THE REASON SO CALL THIS API
"https://fms.bizipac.com/apinew/ws_new/reason.php?leadid=$leadId"










