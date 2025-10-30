class LeadResponse {
  final List<LeadData> data;
  final int total;
  final int success;
  final String message;

  LeadResponse({
    required this.data,
    required this.total,
    required this.success,
    required this.message,
  });

  factory LeadResponse.fromJson(Map<String, dynamic> json) {
    return LeadResponse(
      data: List<LeadData>.from(json['data'].map((x) => LeadData.fromJson(x))),
      total: json['total'],
      success: json['success'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'data': data.map((x) => x.toJson()).toList(),
    'total': total,
    'success': success,
    'message': message,
  };
}

class LeadData {
  final int fiData;
  final String clientMobileApp;
  final String responseId;
  final String transferStatus;
  final String leadId;
  final String mobile;
  final String leadDate;
  final String customerName;
  final String empName;
  final String statusId;
  final String status;
  final String branchId;
  final String branch;
  final String docByTc;
  final String docCollected;
  final String appTime;
  final String clientName;
  final String pincode;
  final String appNo;
  final String appAdd;
  final String appRemark;
  final String subType;
  final String response;
  final String location;
  final String product;
  final String source;
  final String offAddress;
  final String offPincode;
  final String resAddress;
  final String leadType;
  final String appLoc;
  final String formNo;
  final String leadStatus;
  final String clientId;
  final String client_mobile_app;
  final String cpv_url_new;
  final String email;
  final String productCode;
  final String source2;
  final String source3;
  final String callDate;
  final String resPin;
  final String offNo;
  final String doc;
  final String remarks;
  final String pqLeads;
  final String campaignName;
  final String caseId;
  final String surrogate;
  final String seCode;
  final String addOn;
  final String pqKyc;
  final String crmLead;
  final String annualSalary;
  final String yblCustomer;
  final String sourceCode;
  final String asmCode;
  final String lcCode;
  final String dvName;
  final String tokenNo;
  final String accNo;
  final String lgCode;
  final String parErrStatus;
  final String dob;
  final String channelCode;
  final String logo;
  final String secCode;
  final String accHolder;
  final String compName;
  final String compId;
  final String valid;
  final String visitingCard;
  final String utilityBill;
  final String nonPq;
  final String aadharCard;
  final String athenaLeadId;
  final String serviceId;
  final String errStatusId;
  final String url;
  final String cheqeSms;
  final String checkSms;
  final String city;
  final String importTime;
  final String sms;

  // Optional: Add other fields if needed

  LeadData({
    required this.fiData,
    required this.clientMobileApp,
    required this.cpv_url_new,
    required this.responseId,
    required this.transferStatus,
    required this.leadId,
    required this.mobile,
    required this.leadDate,
    required this.customerName,
    required this.empName,
    required this.statusId,
    required this.status,
    required this.branchId,
    required this.branch,
    required this.docByTc,
    required this.docCollected,
    required this.appTime,
    required this.clientName,
    required this.pincode,
    required this.appNo,
    required this.appAdd,
    required this.appRemark,
    required this.subType,
    required this.response,
    required this.location,
    required this.product,
    required this.source,
    required this.offAddress,
    required this.offPincode,
    required this.resAddress,
    required this.leadType,
    required this.appLoc,
    required this.formNo,
    required this.leadStatus,
    required this.clientId,
    required this.client_mobile_app,
    required this.email,
    required this.productCode,
    required this.source2,
    required this.source3,
    required this.callDate,
    required this.resPin,
    required this.offNo,
    required this.doc,
    required this.remarks,
    required this.pqLeads,
    required this.campaignName,
    required this.caseId,
    required this.surrogate,
    required this.seCode,
    required this.addOn,
    required this.pqKyc,
    required this.crmLead,
    required this.annualSalary,
    required this.yblCustomer,
    required this.sourceCode,
    required this.asmCode,
    required this.lcCode,
    required this.dvName,
    required this.tokenNo,
    required this.accNo,
    required this.lgCode,
    required this.parErrStatus,
    required this.dob,
    required this.channelCode,
    required this.logo,
    required this.secCode,
    required this.accHolder,
    required this.compName,
    required this.compId,
    required this.valid,
    required this.visitingCard,
    required this.utilityBill,
    required this.nonPq,
    required this.aadharCard,
    required this.athenaLeadId,
    required this.serviceId,
    required this.errStatusId,
    required this.url,
    required this.cheqeSms,
    required this.checkSms,
    required this.city,
    required this.importTime,
    required this.sms,
  });

  factory LeadData.fromJson(Map<String, dynamic> json) {
    return LeadData(
      fiData: json['fiData'] ?? 0,
      clientMobileApp: json['client_mobile_app'] ?? '',
      cpv_url_new: json['cpv_url_new'] ?? '',
      responseId: json['response_id'] ?? '',
      transferStatus: json['transfer_status'] ?? '',
      leadId: json['lead_id'] ?? '',
      mobile: json['mobile'] ?? '',
      leadDate: json['lead_date'] ?? '',
      customerName: json['customer_name'] ?? '',
      empName: json['emp_name'] ?? '',
      statusId: json['status_id'] ?? '',
      status: json['status'] ?? '',
      branchId: json['branch_id'] ?? '',
      branch: json['branch'] ?? '',
      docByTc: json['doc_by_tc'] ?? '',
      docCollected: json['doc_collected'] ?? '',
      appTime: json['apptime'] ?? '',
      clientName: json['clientname'] ?? '',
      pincode: json['pincode'] ?? '',
      appNo: json['app_no'] ?? '',
      appAdd: json['app_add'] ?? '',
      appRemark: json['app_remark'] ?? '',
      subType: json['sub_type'] ?? '',
      response: json['response'] ?? '',
      location: json['location'] ?? '',
      product: json['product'] ?? '',
      source: json['source'] ?? '',
      offAddress: json['off_address'] ?? '',
      offPincode: json['off_pincode'] ?? '',
      resAddress: json['res_address'] ?? '',
      leadType: json['lead_type'] ?? '',
      appLoc: json['apploc'] ?? '',
      formNo: json['form_no'] ?? '',
      leadStatus: json['lead_status'] ?? '',
      clientId: json['client_id'] ?? '',
      client_mobile_app: json['client_mobile_app'] ?? '',
      email: json['email'] ?? '',
      productCode: json['product_code'] ?? '',
      source2: json['source2'] ?? '',
      source3: json['source3'] ?? '',
      callDate: json['call_date'] ?? '',
      resPin: json['res_pin'] ?? '',
      offNo: json['off_no'] ?? '',
      doc: json['doc'] ?? '',
      remarks: json['remarks'] ?? '',
      pqLeads: json['pq_leads'] ?? '',
      campaignName: json['campaign_name'] ?? '',
      caseId: json['case_id'] ?? '',
      surrogate: json['surrogate'] ?? '',
      seCode: json['se_code'] ?? '',
      addOn: json['add_on'] ?? '',
      pqKyc: json['pq_kyc'] ?? '',
      crmLead: json['crm_lead'] ?? '',
      annualSalary: json['annual_salary'] ?? '',
      yblCustomer: json['YBLCustomer'] ?? '',
      sourceCode: json['source_code'] ?? '',
      asmCode: json['ASM_code'] ?? '',
      lcCode: json['LC_code'] ?? '',
      dvName: json['DV_name'] ?? '',
      tokenNo: json['Token_no'] ?? '',
      accNo: json['accno'] ?? '',
      lgCode: json['lgcode'] ?? '',
      parErrStatus: json['par_err_status'] ?? '',
      dob: json['dob'] ?? '',
      channelCode: json['channelcode'] ?? '',
      logo: json['logo'] ?? '',
      secCode: json['secode'] ?? '',
      accHolder: json['accholder'] ?? '',
      compName: json['compname'] ?? '',
      compId: json['compid'] ?? '',
      valid: json['valid'] ?? '',
      visitingCard: json['visitingcard'] ?? '',
      utilityBill: json['utilitybill'] ?? '',
      nonPq: json['nonpq'] ?? '',
      aadharCard: json['aadharcard'] ?? '',
      athenaLeadId: json['Athena_lead_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      errStatusId: json['err_status_id'] ?? '',
      url: json['url'] ?? '',
      cheqeSms: json['cheqe_sms'] ?? '',
      checkSms: json['check_sms'] ?? '',
      city: json['city'] ?? '',
      importTime: json['importtime'] ?? '',
      sms: json['sms'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'fiData': fiData,
    'client_mobile_app': clientMobileApp,
    'cpv_url_new': cpv_url_new,
    'response_id': responseId,
    'transfer_status': transferStatus,
    'lead_id': leadId,
    'mobile': mobile,
    'lead_date': leadDate,
    'customer_name': customerName,
    'emp_name': empName,
    'status_id': statusId,
    'status': status,
    'branch_id': branchId,
    'branch': branch,
    'doc_by_tc': docByTc,
    'doc_collected': docCollected,
    'apptime': appTime,
    'clientname': clientName,
    'pincode': pincode,
    'app_no': appNo,
    'app_add': appAdd,
    'app_remark': appRemark,
    'sub_type': subType,
    'response': response,
    'location': location,
    'product': product,
    'source': source,
    'off_address': offAddress,
    'off_pincode': offPincode,
    'res_address': resAddress,
    'lead_type': leadType,
    'apploc': appLoc,
    'form_no': formNo,
    'lead_status': leadStatus,
    'client_id': clientId,
    'client_mobile_app': client_mobile_app,
    'email': email,
    'product_code': productCode,
    'source2': source2,
    'source3': source3,
    'call_date': callDate,
    'res_pin': resPin,
    'off_no': offNo,
    'doc': doc,
    'remarks': remarks,
    'pq_leads': pqLeads,
    'campaign_name': campaignName,
    'case_id': caseId,
    'surrogate': surrogate,
    'se_code': seCode,
    'add_on': addOn,
    'pq_kyc': pqKyc,
    'crm_lead': crmLead,
    'annual_salary': annualSalary,
    'YBLCustomer': yblCustomer,
    'source_code': sourceCode,
    'ASM_code': asmCode,
    'LC_code': lcCode,
    'DV_name': dvName,
    'Token_no': tokenNo,
    'accno': accNo,
    'lgcode': lgCode,
    'par_err_status': parErrStatus,
    'dob': dob,
    'channelcode': channelCode,
    'logo': logo,
    'secode': secCode,
    'accholder': accHolder,
    'compname': compName,
    'compid': compId,
    'valid': valid,
    'visitingcard': visitingCard,
    'utilitybill': utilityBill,
    'nonpq': nonPq,
    'aadharcard': aadharCard,
    'Athena_lead_id': athenaLeadId,
    'service_id': serviceId,
    'err_status_id': errStatusId,
    'url': url,
    'cheqe_sms': cheqeSms,
    'check_sms': checkSms,
    'city': city,
    'importtime': importTime,
    'sms': sms,
  };
}
