import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:peckme/model/DocumentResponse.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import '../../controller/document_controller.dart';
import '../../controller/document_list_controller.dart';
import '../../model/PdfImageUrlModel.dart';
import '../../model/collected_doc_model.dart';
import '../../services/aadhar_masking_service.dart';
import '../../utils/app_constant.dart';
import '../../services/image_to_pdf.dart';
import 'custome_crop_screen.dart';

class DocumentScreenTest extends StatefulWidget {
  final String clientName;
  final String clientId;
  final String leadId;
  final String userName;

  const DocumentScreenTest({
    Key? key,
    required this.clientName,
    required this.leadId,
    required this.clientId,
    required this.userName,
  }) : super(key: key);

  @override
  State<DocumentScreenTest> createState() => _DocumentScreenTestState();
}

class _DocumentScreenTestState extends State<DocumentScreenTest> {
  late Future<DocumentResponse?> futureDocuments;
  final DocumentService _documentService = DocumentService();
  String uid = '';
  String name = '';

  //signature start
  Uint8List? signatureImage; // Store signature image
  String? signatureImageUrl; // Store uploaded PDF URL

  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool isSaving = false; // 🔹 Add this at class level

  void _openSignaturePad(String docName) {
    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text('Signature'),
                content: SizedBox(
                  height: 400,
                  width: 400,
                  child: Signature(
                    controller: _controller,
                    backgroundColor: Colors.grey[200]!,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => _controller.clear(),
                    child: const Text('Clear'),
                  ),
                  isSaving
                      ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : ElevatedButton(
                    onPressed: () async {
                      setStateDialog(() => isSaving = true); // show loader
                      await _saveSignature(docname: docName);
                      setStateDialog(() => isSaving = false); // hide loader
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Save signature as image and generate PDF
  Future<void> _saveSignature({required String docname}) async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please draw a signature')));
      return;
    }

    // Convert to PNG
    final Uint8List? data = await _controller.toPngBytes();
    if (data == null) return;

    // Save locally as PNG
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/signature.png');
    await file.writeAsBytes(data);

    setState(() {
      signatureImage = data; // Show in UI
    });

    print("✅ Signature image saved at: ${file.path}");

    // Convert to PDF & upload
    final url = await convertImageToPdfAndSave(
      file,
      // <-- Pass File, not String
      "51",
      widget.clientName,
      widget.leadId,
      uid,
      'Signature',
      widget.userName,
    );
    if (url == null) return null;

    // ✅ New CollectedDoc (without name)
    final doc = CollectedDoc(path: file.path, pdfUrl: url);

    setState(() {
      collectedDocs.add(doc);
    });

    await _saveOrUpdateDocs(collectedDocs);

    if (url != null) {
      signatureImageUrl = url;
      print("📄 Signature uploaded.");
    } else {
      print("❌ Signature failed.");
    }

    _controller.clear();
    Navigator.pop(context); // Close dialog
  }

  //signature end
  void loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getString('uid') ?? '';
      name = prefs.getString('name') ?? '';
    });
  }

  List<CollectedDoc> collectedDocs = [];

  //category=="PHOTO" START CODE
  bool isLoadingPhoto = false;
  bool isLoadingfeSelfie = false;
  bool isLoadingfESelfieWithPerson = false;
  bool isLoadingcompanuBoard = false;
  bool isLoadingbillDesk = false;
  bool isLoadingfrontDoor = false;
  bool isLoadinglocationSnap = false;
  bool isLoadingnamePstatic = false;
  bool isLoadingpremisesInterior = false;
  bool isLoadingstock = false;
  bool isLoadingimageOfPersonMet = false;
  bool isLoadingbillDeskImageofShop = false;
  bool isLoadingimageofShopFromOutside = false;
  bool isLoadingqRCode = false;
  bool isLoadingtentCard = false;
  bool isLoadingpoliticalConnections = false;

  File? feSelfie;
  String? feSelfieUrl;
  File? companuBoard;
  String? companuBoardUrl;
  File? billDesk;
  String? billDeskUrl;
  File? frontDoor;
  String? frontDoorUrl;
  File? locationSnap;
  String? locationSnapUrl;
  File? namePstatic;
  String? namePstaticUrl;
  File? premisesInterior;
  String? premisesInteriorUrl;
  File? stock;
  String? stockUrl;
  File? photo;
  String? photoUrl;
  File? fESelfieWithPerson;
  String? fESelfieWithPersonUrl;
  File? imageOfPersonMet;
  String? imageOfPersonMetUrl;
  File? billDeskImageofShop;
  String? billDeskImageofShopUrl;
  File? imageofShopFromOutside;
  String? imageofShopFromOutsideUrl;
  File? qRCode;
  String? qRCodeUrl;
  File? tentCard;
  String? tentCardUrl;
  File? politicalConnections;
  String? politicalConnectionsUrl;

  Future pickImageCompanyBoard(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingcompanuBoard = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingcompanuBoard = false;
      if (img != null) {
        companuBoard = img.croppedImage;
        companuBoardUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageFeSelfie(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingfeSelfie = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingfeSelfie = false;
      if (img != null) {
        feSelfie = img.croppedImage;
        feSelfieUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageBillDesk(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingbillDesk = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingbillDesk = false;
      if (img != null) {
        billDesk = img.croppedImage;
        billDeskUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageFrontDoor(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingfrontDoor = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingfrontDoor = false;
      if (img != null) {
        frontDoor = img.croppedImage;
        frontDoorUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageLocationSnap(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadinglocationSnap = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadinglocationSnap = false;
      if (img != null) {
        locationSnap = img.croppedImage;
        locationSnapUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageNamePstatic(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingnamePstatic = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingnamePstatic = false;
      if (img != null) {
        namePstatic = img.croppedImage;
        namePstaticUrl = img.pdfUrl;
      }
    });
  }

  Future pickImagePremisesInterior(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingpremisesInterior = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingpremisesInterior = false;
      if (img != null) {
        premisesInterior = img.croppedImage;
        premisesInteriorUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageStock(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingstock = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingstock = false;
      if (img != null) {
        stock = img.croppedImage;
        stockUrl = img.pdfUrl;
      }
    });
  }

  Future pickImagePhoto1(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingPhoto = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingPhoto = false;
      if (img != null) {
        photo = img.croppedImage;
        photoUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageFESelfieWithPerson1(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingfESelfieWithPerson = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingfESelfieWithPerson = false;
      if (img != null) {
        fESelfieWithPerson = img.croppedImage;
        fESelfieWithPersonUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageImageOfPersonMet(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingimageOfPersonMet = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingimageOfPersonMet = false;
      if (img != null) {
        imageOfPersonMet = img.croppedImage;
        imageOfPersonMetUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageBillDeskImageofShop(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingbillDeskImageofShop = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingbillDeskImageofShop = false;
      if (img != null) {
        billDeskImageofShop = img.croppedImage;
        billDeskImageofShopUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageImageofShopFromOutside(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingimageofShopFromOutside = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingimageofShopFromOutside = false;
      if (img != null) {
        imageofShopFromOutside = img.croppedImage;
        imageofShopFromOutsideUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageQRCode(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingqRCode = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingqRCode = false;
      if (img != null) {
        qRCode = img.croppedImage;
        qRCodeUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageTentCard(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingtentCard = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingtentCard = false;
      if (img != null) {
        tentCard = img.croppedImage;
        tentCardUrl = img.pdfUrl;
      }
    });
  }

  Future pickImagePoliticalConnections(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingpoliticalConnections = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingpoliticalConnections = false;
      if (img != null) {
        politicalConnections = img.croppedImage;
        politicalConnectionsUrl = img.pdfUrl;
      }
    });
  }

  //category=="PHOTO" END CODE
  //category=="ID PROOF" START CODE
  bool isLoadingiDProofofPersonMet = false;
  bool isLoadingpancard = false;

  File? iDProofofPersonMet;
  String? iDProofofPersonMetUrl;
  File? pancard;
  String? pancardUrl;

  Future pickImageIDProofofPersonMet(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingiDProofofPersonMet = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingiDProofofPersonMet = false;
      if (img != null) {
        iDProofofPersonMet = img.croppedImage;
        iDProofofPersonMetUrl = img.pdfUrl;
      }
    });
  }

  Future pickImagePancard(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingpancard = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingpancard = false;
      if (img != null) {
        pancard = img.croppedImage;
        pancardUrl = img.pdfUrl;
      }
    });
  }

  //category=="ID PROOF" END CODE
  //category=="OTHERS" START CODE
  bool isLoadingAnnexure = false;
  bool isLoadingOthers = false;
  bool isLoading1monthBankStatement = false;
  bool isLoadingCancelledCheque = false;
  bool isLoadingCompanyID = false;
  bool isLoadingCompletelyFilledJob = false;
  bool isLoadingDueDiligenceForm = false;
  bool isLoadingForm26AS = false;
  bool isLoadingForm60 = false;
  bool isLoadingGazetteCertificate = false;
  bool isLoadingGSTAnnexA = false;
  bool isLoadingGSTAnnexB = false;
  bool isLoadingLoanAgreement = false;
  bool isLoadingMarriageCertificate = false;
  bool isLoadingNachOnly = false;
  bool isLoadingOVDDeclaration = false;
  bool isLoadingPODImage = false;
  bool isLoadingCheques = false;
  bool isLoadingAuthSignForm = false;
  bool isLoadingShopEstablishmentCertificate = false;

  File? annexure;
  String? annexureUrl;
  File? others;
  String? othersUrl;
  File? oneMonthBankStatement;
  String? oneMonthBankStatementUrl;
  File? cancelledCheque;
  String? cancelledChequeUrl;
  File? companyID;
  String? companyIDUrl;
  File? completelyFilledJob;
  String? completelyFilledJobUrl;
  File? dueDiligenceForm;
  String? dueDiligenceFormUrl;
  File? form26AS;
  String? form26ASUrl;
  File? form60;
  String? form60Url;
  File? gazetteCertificate;
  String? gazetteCertificateUrl;
  File? gSTAnnexA;
  String? gSTAnnexAUrl;
  File? gSTAnnexB;
  String? gSTAnnexBUrl;
  File? loanAgreement;
  String? loanAgreementUrl;
  File? marriageCertificate;
  String? marriageCertificateUrl;
  File? nachOnly;
  String? nachOnlyUrl;
  File? oVDDeclaration;
  String? oVDDeclarationUrl;
  File? pODImage;
  String? pODImageUrl;
  File? cheques;
  String? chequesUrl;
  File? authSignForm;
  String? authSignFormUrl;
  File? shopEstablishmentCertificate;
  String? shopEstablishmentCertificateUrl;

  Future pickImageAnnexure(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingAnnexure = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingAnnexure = false;
      if (img != null) {
        annexure = img.croppedImage;
        annexureUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageOthers(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingOthers = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingOthers = false;
      if (img != null) {
        others = img.croppedImage;
        othersUrl = img.pdfUrl;
      }
    });
  }

  Future pickImage1monthBankStatement(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoading1monthBankStatement = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoading1monthBankStatement = false;
      if (img != null) {
        oneMonthBankStatement = img.croppedImage;
        oneMonthBankStatementUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageCancelledCheque(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingCancelledCheque = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingCancelledCheque = false;
      if (img != null) {
        cancelledCheque = img.croppedImage;
        cancelledChequeUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageCompanyID(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingCompanyID = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingCompanyID = false;
      if (img != null) {
        companyID = img.croppedImage;
        companyIDUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageCompletelyFilledJob(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingCompletelyFilledJob = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingCompletelyFilledJob = false;
      if (img != null) {
        completelyFilledJob = img.croppedImage;
        completelyFilledJobUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageDueDiligenceForm(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingDueDiligenceForm = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingDueDiligenceForm = false;
      if (img != null) {
        dueDiligenceForm = img.croppedImage;
        dueDiligenceFormUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageForm26AS(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingForm26AS = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingForm26AS = false;
      if (img != null) {
        form26AS = img.croppedImage;
        form26ASUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageForm60(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingForm60 = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingForm60 = false;
      if (img != null) {
        form60 = img.croppedImage;
        form60Url = img.pdfUrl;
      }
    });
  }

  Future pickImageGazetteCertificate(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingGazetteCertificate = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingGazetteCertificate = false;
      if (img != null) {
        gazetteCertificate = img.croppedImage;
        gazetteCertificateUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageGSTAnnexA(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingGSTAnnexA = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingGSTAnnexA = false;
      if (img != null) {
        gSTAnnexA = img.croppedImage;
        gSTAnnexAUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageGSTAnnexB(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingGSTAnnexB = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingGSTAnnexB = false;
      if (img != null) {
        gSTAnnexB = img.croppedImage;
        gSTAnnexBUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageLoanAgreement(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingLoanAgreement = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingLoanAgreement = false;
      if (img != null) {
        loanAgreement = img.croppedImage;
        loanAgreementUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageMarriageCertificate(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingMarriageCertificate = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingMarriageCertificate = false;
      if (img != null) {
        marriageCertificate = img.croppedImage;
        marriageCertificateUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageNachOnly(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingNachOnly = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingNachOnly = false;
      if (img != null) {
        nachOnly = img.croppedImage;
        nachOnlyUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageOVDDeclaration(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingOVDDeclaration = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingOVDDeclaration = false;
      if (img != null) {
        oVDDeclaration = img.croppedImage;
        oVDDeclarationUrl = img.pdfUrl;
      }
    });
  }

  Future pickImagePODImage(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingPODImage = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingPODImage = false;
      if (img != null) {
        pODImage = img.croppedImage;
        pODImageUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageCheques(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingCheques = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingCheques = false;
      if (img != null) {
        cheques = img.croppedImage;
        chequesUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageAuthSignForm(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingAuthSignForm = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingAuthSignForm = false;
      if (img != null) {
        authSignForm = img.croppedImage;
        authSignFormUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageShopEstablishmentCertificate(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingShopEstablishmentCertificate = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingShopEstablishmentCertificate = false;
      if (img != null) {
        shopEstablishmentCertificate = img.croppedImage;
        shopEstablishmentCertificateUrl = img.pdfUrl;
      }
    });
  }

  //category=="OTHERS" END CODE
  //category=="ADD PROOF" START CODE
  bool isLoadingAadhaarBack = false;
  bool isLoadingAadhaarFront = false;
  bool isLoadingAllotmentLetter = false;
  bool isLoadingDrivingLicense = false;
  bool isLoadingElectricityBill = false;
  bool isLoadingGasBill = false;
  bool isLoadingLandLineBill = false;
  bool isLoadingMaintainanceReceipt = false;
  bool isLoadingMobileBill = false;
  bool isLoadingMunicipalityWaterBill = false;
  bool isLoadingPassport = false;
  bool isLoadingPostOfficeSB = false;
  bool isLoadingRegisteredRent = false;
  bool isLoadingRegisteredSales = false;
  bool isLoadingRentAgreement = false;
  bool isLoadingVoterCard = false;

  File? aadhaarBack;
  String? aadhaarBackUrl;
  File? aadhaarFront;
  String? aadhaarFrontUrl;
  File? allotmentLetter;
  String? allotmentLetterUrl;
  File? drivingLicense;
  String? drivingLicenseUrl;
  File? electricityBill;
  String? electricityBillUrl;
  File? gasBill;
  String? gasBillUrl;
  File? landLineBill;
  String? landLineBillUrl;
  File? maintainanceReceipt;
  String? maintainanceReceiptUrl;
  File? mobileBill;
  String? mobileBillUrl;
  File? municipalityWaterBill;
  String? municipalityWaterBillUrl;
  File? passport;
  String? passportUrl;
  File? postOfficeSB;
  String? postOfficeSBUrl;
  File? registeredRent;
  String? registeredRentUrl;
  File? registeredSales;
  String? registeredSalesUrl;
  File? rentAgreement;
  String? rentAgreementUrl;
  File? voterCard;
  String? voterCardUrl;

  Future pickImageAadhaarBack(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingAadhaarBack = true);
    final img = await _pickAndUploadAadharMasking(source, docname, documentId);
    setState(() {
      isLoadingAadhaarBack = false;
      if (img != null) {
        aadhaarBack = img.croppedImage;
        aadhaarBackUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageAadhaarFront(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingAadhaarFront = true);
    final img = await _pickAndUploadAadharMasking(source, docname, documentId);
    setState(() {
      isLoadingAadhaarFront = false;
      if (img != null) {
        aadhaarFront = img.croppedImage;
        aadhaarFrontUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageAllotmentLetter(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingAllotmentLetter = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingAllotmentLetter = false;
      if (img != null) {
        allotmentLetter = img.croppedImage;
        allotmentLetterUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageDrivingLicense(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingDrivingLicense = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingDrivingLicense = false;
      if (img != null) {
        drivingLicense = img.croppedImage;
        drivingLicenseUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageElectricityBill(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingElectricityBill = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingElectricityBill = false;
      if (img != null) {
        electricityBill = img.croppedImage;
        electricityBillUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageGasBill(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingGasBill = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingGasBill = false;
      if (img != null) {
        gasBill = img.croppedImage;
        gasBillUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageLandLineBill(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingLandLineBill = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingLandLineBill = false;
      if (img != null) {
        landLineBill = img.croppedImage;
        landLineBillUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageMaintainanceReceipt(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingMaintainanceReceipt = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingMaintainanceReceipt = false;
      if (img != null) {
        maintainanceReceipt = img.croppedImage;
        maintainanceReceiptUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageMobileBill(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingMobileBill = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingMobileBill = false;
      if (img != null) {
        mobileBill = img.croppedImage;
        mobileBillUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageMunicipalityWaterBill(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingMunicipalityWaterBill = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingMunicipalityWaterBill = false;
      if (img != null) {
        municipalityWaterBill = img.croppedImage;
        municipalityWaterBillUrl = img.pdfUrl;
      }
    });
  }

  Future pickImagePassport(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingPassport = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingPassport = false;
      if (img != null) {
        passport = img.croppedImage;
        passportUrl = img.pdfUrl;
      }
    });
  }

  Future pickImagePostOfficeSB(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingPostOfficeSB = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingPostOfficeSB = false;
      if (img != null) {
        postOfficeSB = img.croppedImage;
        postOfficeSBUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageRegisteredRent(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingRegisteredRent = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingRegisteredRent = false;
      if (img != null) {
        registeredRent = img.croppedImage;
        registeredRentUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageRegisteredSales(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingRegisteredSales = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingRegisteredSales = false;
      if (img != null) {
        registeredSales = img.croppedImage;
        registeredSalesUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageRentAgreement(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingRentAgreement = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingRentAgreement = false;
      if (img != null) {
        rentAgreement = img.croppedImage;
        rentAgreementUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageVoterCard(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingVoterCard = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingVoterCard = false;
      if (img != null) {
        voterCard = img.croppedImage;
        voterCardUrl = img.pdfUrl;
      }
    });
  }

  //category=="ADD PROOF" END CODE

  //START CODE CATEGORY=="INCOME PROOF"
  bool isLoadingCreditCardCopy = false;
  bool isLoadingITRComputation = false;
  bool isLoadingLatestCreditCard = false;
  bool isLoadingLatestSalarySlip = false;
  bool isLoadingSalarySlip = false;

  File? creditCardCopy;
  String? creditCardCopyUrl;
  File? iTRComputation;
  String? iTRComputationUrl;
  File? latestCreditCard;
  String? latestCreditCardUrl;
  File? latestSalarySlip;
  String? latestSalarySlipUrl;
  File? salarySlip;
  String? salarySlipUrl;

  Future pickImageCreditCardCopy(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingCreditCardCopy = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingCreditCardCopy = false;
      if (img != null) {
        creditCardCopy = img.croppedImage;
        creditCardCopyUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageITRComputation(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingITRComputation = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingITRComputation = false;
      if (img != null) {
        iTRComputation = img.croppedImage;
        iTRComputationUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageLatestCreditCard(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingLatestCreditCard = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingLatestCreditCard = false;
      if (img != null) {
        latestCreditCard = img.croppedImage;
        latestCreditCardUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageLatestSalarySlip(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingLatestSalarySlip = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingLatestSalarySlip = false;
      if (img != null) {
        latestSalarySlip = img.croppedImage;
        latestSalarySlipUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageSalarySlip(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingSalarySlip = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingSalarySlip = false;
      if (img != null) {
        salarySlip = img.croppedImage;
        salarySlipUrl = img.pdfUrl;
      }
    });
  }

  //END CODE CATEGORY=="INCOME PROOF"
  //START CODE CATEGORY=="ADD AND INCOME PROOF"
  bool isLoading3MonthsBankStatement = false;
  bool isLoadingBankPassbook = false;

  File? threeMonthsBankStatement;
  String? threeMonthsBankStatementUrl;
  File? bankPassbook;
  String? bankPassbookUrl;

  Future pickImage3MonthsBankStatement(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoading3MonthsBankStatement = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoading3MonthsBankStatement = false;
      if (img != null) {
        threeMonthsBankStatement = img.croppedImage;
        threeMonthsBankStatementUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageBankPassbook(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingBankPassbook = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingBankPassbook = false;
      if (img != null) {
        bankPassbook = img.croppedImage;
        bankPassbookUrl = img.pdfUrl;
      }
    });
  }

  //END CODE CATEGORY=="ADD AND INCOME PROOF"
  //START CODE CATEGORY=="ID AND ADD PROOF"
  bool isLoadingDrivingLicenseAddProof = false;
  bool isLoadingNREGACard = false;
  bool isLoadingPassportAddProof = false;

  File? drivingLicenseAddProof;
  String? drivingLicenseAddProofUrl;
  File? nREGACard;
  String? nREGACardUrl;
  File? passportAddProof;
  String? passportAddProofUrl;

  Future pickImageDrivingLicenseAddProof(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingDrivingLicenseAddProof = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingDrivingLicenseAddProof = false;
      if (img != null) {
        drivingLicenseAddProof = img.croppedImage;
        drivingLicenseAddProofUrl = img.pdfUrl;
      }
    });
  }

  Future pickImageNREGACard(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingNREGACard = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingNREGACard = false;
      if (img != null) {
        nREGACard = img.croppedImage;
        nREGACardUrl = img.pdfUrl;
      }
    });
  }

  Future pickImagePassportAddProof(ImageSource source,
      String docname,
      String documentId,) async {
    setState(() => isLoadingPassportAddProof = true);
    final img = await _pickAndUploadImage(source, docname, documentId);
    setState(() {
      isLoadingPassportAddProof = false;
      if (img != null) {
        passportAddProof = img.croppedImage;
        passportAddProofUrl = img.pdfUrl;
      }
    });
  }

  //END CODE CATEGORY=="ID AND ADD PROOF"

  File? selectedImage;
  String? selectedImageUrl;

  void _showAddDialog({required String docName, required String docId}) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        bool isUploading = false; // ✅ local state for loading

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Upload multiple images",
                style: TextStyle(
                  fontSize: 15,
                  color: AppConstant.darkHeadingColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Container(
                height: MediaQuery
                    .of(context)
                    .size
                    .height / 10,
                width: 500,
                color: Colors.white60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 75,
                          width: 75,
                          decoration: BoxDecoration(
                            color: AppConstant.darkButton,
                            border: Border.all(color: Colors.black, width: 1.0),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Center(
                            child: isUploading
                                ? const CircularProgressIndicator() // ✅ loader
                                : selectedImage == null
                                ? InkWell(
                              onTap: () async {
                                setStateDialog(() {
                                  isUploading = true;
                                });
                                final img = await _pickAndUploadImage(
                                  ImageSource.camera,
                                  docId,
                                  docName,
                                );

                                if (img != null) {
                                  setStateDialog(() {
                                    selectedImage = img.croppedImage;
                                    selectedImageUrl = img.pdfUrl;
                                  });
                                }

                                setStateDialog(() {
                                  isUploading = false;
                                });
                              },
                              child: const Text(
                                "No image selected",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                ),
                              ),
                            )
                                : Container(
                              height: 73,
                              width: 73,
                              color: Colors.white,
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: 2,
                          child: InkWell(
                            onTap: () async {
                              try {
                                if (selectedImage != null &&
                                    selectedImageUrl != null) {
                                  // 🔹 पहले Database से delete
                                  bool success = await deleteDocumentFromDB(
                                    uid,
                                    selectedImageUrl!,
                                  );

                                  if (success) {
                                    // 🔹 Local file भी delete
                                    await selectedImage!.delete();
                                    setState(() {
                                      selectedImage = null;
                                      selectedImageUrl = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("✅ Deleted successfully"),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "❌ Failed to delete from DB",
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                print("Error deleting file: $e");
                              }
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: const Icon(
                                Icons.delete_forever_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          docName,
                          textAlign: TextAlign.left,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // ✅ Dono buttons only show if selectedImage != null
                if (selectedImage != null) ...[
                  TextButton(
                    onPressed: () async {
                      bool success = await deleteDocumentFromDB(
                        uid,
                        selectedImageUrl!,
                      );
                      if (success) {
                        // 🔹 Local file bhi delete
                        await selectedImage!.delete();
                        setState(() {
                          selectedImage = null;
                          selectedImageUrl = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("❌ Cancelled")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("❌ Failed to delete from DB"),
                          ),
                        );
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text("Cancel"),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx, selectedImage);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Image upload successfully"),
                        ),
                      );
                      setState(() {
                        selectedImage = null;
                        selectedImageUrl = null;
                      });
                    },
                    child: const Text("Ok"),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<UploadResult?> _pickAndUploadImage(ImageSource source,
      String docname,
      String documentId,) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return null;

      File? img = File(image.path);

      // Custom crop screen
      File? cropped = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomCropScreen(imageFile: img),
        ),
      );

      if (cropped == null) {
        print("⚠️ Cropping cancelled");
        return null;
      }

      // PDF generate karna
      final url = await convertImageToPdfAndSave(
        cropped,
        docname,
        widget.clientName,
        widget.leadId,
        uid,
        documentId,
        widget.userName,
      );

      if (url == null) return null;

      // ✅ New CollectedDoc (without name)
      final doc = CollectedDoc(path: cropped.path, pdfUrl: url);

      setState(() {
        collectedDocs.add(doc);
      });

      await _saveOrUpdateDocs(collectedDocs);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Document saved"),
          duration: Duration(seconds: 3),
        ),
      );

      return UploadResult(croppedImage: cropped, pdfUrl: url);
    } catch (e) {
      print("❌ Error: $e");
      return null;
    }
  }

  late final AadhaarMaskService _aadhaarService = AadhaarMaskService();

  Future<UploadResult?> _pickAndUploadAadharMasking(ImageSource source,
      String docName,
      String documentId,) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return null;

      File img = File(image.path);

      // Step 1️⃣ — Open crop screen
      File? cropped = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomCropScreen(imageFile: img),
        ),
      );

      if (cropped == null) {
        print("⚠️ Cropping cancelled");
        return null;
      }

      // Step 2️⃣ — Aadhaar Masking (after crop)

      final result = await _aadhaarService.processImage(cropped);

      // Optional: draw black boxes on cropped image & save to new file
      File maskedFile = await _drawAndSaveMaskedImage(
        cropped,
        result.redactRects,
      );

      print("✅ Detected Aadhaar: ${result.maskedAadhaar}");

      // Step 3️⃣ — Convert masked image to PDF
      final url = await convertImageToPdfAndSave(
        maskedFile,
        // ← use masked file now
        docName,
        widget.clientName,
        widget.leadId,
        uid,
        documentId,
        widget.userName,
      );

      if (url == null) return null;

      // Step 4️⃣ — Add to local list
      final doc = CollectedDoc(path: maskedFile.path, pdfUrl: url);
      setState(() {
        collectedDocs.add(doc);
      });

      await _saveOrUpdateDocs(collectedDocs);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Document saved"),
          duration: Duration(seconds: 3),
        ),
      );

      return UploadResult(croppedImage: maskedFile, pdfUrl: url);
    } catch (e, st) {
      print("❌ Error while processing Aadhaar masking: $e\n$st");
      return null;
    }
  }

  Future<File> _drawAndSaveMaskedImage(File original,
      List<Rect> redacts,) async {
    final bytes = await original.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Draw original image
    canvas.drawImage(image, Offset.zero, paint);

    // Draw redaction rectangles
    paint.color = const Color(0xFF000000);
    for (final r in redacts) {
      canvas.drawRect(r, paint);
    }

    // Convert to PNG bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(image.width, image.height);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    // Save to file
    final maskedFile = File(
      '${original.parent.path}/masked_${DateTime
          .now()
          .millisecondsSinceEpoch}.png',
    );
    await maskedFile.writeAsBytes(pngBytes!.buffer.asUint8List());

    return maskedFile;
  }

  Future<bool> deleteDocumentFromDB(String uid, String docUrl) async {
    try {
      final response = await http.post(
        Uri.parse("https://fms.bizipac.com/apinew/ws_new/delete_document.php?"),
        body: {"loginid": uid, "document_file": docUrl},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("---------");
        print(data);
        print("---------");
        return data["success"] == 1;
      }
    } catch (e) {
      print("❌ Error calling delete API: $e");
    }
    return false;
  }

  Future<void> _saveOrUpdateDocs(List<CollectedDoc> docs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = docs.map((d) => d.toJson()).toList();
    await prefs.setString("collectedDocs", jsonEncode(jsonList));
  }

  Future<void> _loadCollectedDocs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("collectedDocs");
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        collectedDocs = jsonList
            .map((j) => CollectedDoc.fromJson(j))
            .cast<CollectedDoc>()
            .toList();
      });
    }
  }

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // हर 1 सेकंड में check करेगा
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      checkInternetSpeed();
    });
    loadUserData();
    _loadCollectedDocs();
    futureDocuments = DocumentController.fetchDocument();
    // _futureDocumentsList = _documentService.fetchDocuments();
  }

  @override
  void dispose() {
    _timer?.cancel();
    photo = null;
    selectedImage = null;
    annexure = null;
    photoUrl = null;
    others = null;
    othersUrl = null;
    selectedImageUrl = null;
    annexureUrl = null;
    feSelfie = null;
    companuBoard = null;
    companuBoardUrl = null;
    billDesk = null;
    billDeskUrl = null;
    frontDoor = null;
    frontDoorUrl = null;
    locationSnap = null;
    locationSnapUrl = null;
    namePstatic = null;
    namePstaticUrl = null;
    premisesInterior = null;
    premisesInteriorUrl = null;
    stock = null;
    stockUrl = null;
    fESelfieWithPerson = null;
    fESelfieWithPersonUrl = null;
    imageOfPersonMet = null;
    imageOfPersonMetUrl = null;
    billDeskImageofShop = null;
    billDeskImageofShopUrl = null;
    imageofShopFromOutside = null;
    imageofShopFromOutsideUrl = null;
    qRCode = null;
    qRCodeUrl = null;
    tentCard = null;
    tentCardUrl = null;
    politicalConnections = null;
    politicalConnectionsUrl = null;
    iDProofofPersonMet = null;
    iDProofofPersonMetUrl = null;
    pancard = null;
    pancardUrl = null;
    oneMonthBankStatement = null;
    oneMonthBankStatementUrl = null;
    cancelledCheque = null;
    cancelledChequeUrl = null;
    companyID = null;
    companyIDUrl = null;
    completelyFilledJob = null;
    completelyFilledJobUrl = null;
    dueDiligenceForm = null;
    dueDiligenceFormUrl = null;
    form26AS = null;
    form26ASUrl = null;
    form60 = null;
    form60Url = null;
    gazetteCertificate = null;
    gazetteCertificateUrl = null;
    gSTAnnexA = null;
    gSTAnnexAUrl = null;
    gSTAnnexB = null;
    gSTAnnexBUrl = null;
    loanAgreement = null;
    loanAgreementUrl = null;
    marriageCertificate = null;
    marriageCertificateUrl = null;
    nachOnly = null;
    nachOnlyUrl = null;
    oVDDeclaration = null;
    oVDDeclarationUrl = null;
    pODImage = null;
    pODImageUrl = null;
    cheques = null;
    chequesUrl = null;
    authSignForm = null;
    authSignFormUrl = null;
    shopEstablishmentCertificate = null;
    shopEstablishmentCertificateUrl = null;
    aadhaarBack = null;
    aadhaarBackUrl = null;
    aadhaarFront = null;
    aadhaarFrontUrl = null;
    allotmentLetter = null;
    allotmentLetterUrl = null;
    drivingLicense = null;
    drivingLicenseUrl = null;
    electricityBill = null;
    electricityBillUrl = null;
    gasBill = null;
    gasBillUrl = null;
    landLineBill = null;
    landLineBillUrl = null;
    maintainanceReceipt = null;
    maintainanceReceiptUrl = null;
    mobileBill = null;
    mobileBillUrl = null;
    municipalityWaterBill = null;
    municipalityWaterBillUrl = null;
    passport = null;
    passportUrl = null;
    postOfficeSB = null;
    postOfficeSBUrl = null;
    registeredRent = null;
    registeredRentUrl = null;
    registeredSales = null;
    registeredSalesUrl = null;
    rentAgreement = null;
    rentAgreementUrl = null;
    voterCard = null;
    voterCardUrl = null;
    creditCardCopy = null;
    creditCardCopyUrl = null;
    iTRComputation = null;
    iTRComputationUrl = null;
    latestCreditCard = null;
    latestCreditCardUrl = null;
    latestSalarySlip = null;
    latestSalarySlipUrl = null;
    salarySlip = null;
    salarySlipUrl = null;
    threeMonthsBankStatement = null;
    threeMonthsBankStatementUrl = null;
    bankPassbook = null;
    bankPassbookUrl = null;
    drivingLicenseAddProof = null;
    drivingLicenseAddProofUrl = null;
    nREGACard = null;
    nREGACardUrl = null;
    passportAddProof = null;
    passportAddProofUrl = null;
    signatureImage = null;
    super.dispose();
  }

  Future<void> checkInternetSpeed() async {
    final url = Uri.parse("https://www.google.com/generate_204");
    final stopwatch = Stopwatch()
      ..start();

    String? msg;

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (response.statusCode == 204 || response.statusCode == 200) {
        final ms = stopwatch.elapsedMilliseconds;

        if (ms >= 500) {
          msg = "🐌 Internet Slow (${ms}ms)";
        } else {
          msg = null; // 🚫 Fast/Average पर कुछ मत दिखाओ
        }
      } else {
        msg = "❌ No Internet / Error";
      }
    } catch (e) {
      msg = "❌ No Internet / Timeout";
    }

    // ✅ सिर्फ Slow/No Internet पर ही दिखाओ
    if (mounted && msg != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
      );
    }
  }

  bool isCollapsed = false; // 👈 yeh class ke andar define karo
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          "Documents Upload",
          style: TextStyle(color: AppConstant.appBarWhiteColor, fontSize: 18),
        ),
      ),
      body: FutureBuilder<DocumentResponse?>(
        future: futureDocuments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No documents found"));
          }

          final documents = snapshot.data!.doclist;
          // ✅ Group documents by category
          final Map<String, List<Doc>> groupedDocs = {};
          for (var doc in documents) {
            groupedDocs.putIfAbsent(doc.docCategory, () => []).add(doc);
          }
          final data = documents.first.docClient[0].toString();
          return ListView(
            children: groupedDocs.entries.map((entry) {
              final category = entry.key;
              final docs = entry.value;

              // 👉 Check if category should be visible
              final bool categoryHasAccess = docs.any((doc) {
                final clientIds = doc.docClient
                    .split(",")
                    .map((id) => id.trim())
                    .toList();
                return clientIds.contains(widget.clientId.toString().trim()) ||
                    clientIds.contains(
                      "0",
                    ); // ✅ अगर "0" हो तो भी category show होगी
              });

              if (!categoryHasAccess) {
                return const SizedBox.shrink(); // Category ही मत दिखाओ
              }

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: docs.map((doc) {
                    final clientIds = doc.docClient
                        .split(",")
                        .map((id) => id.trim())
                        .toList();
                    final bool belongsToClient = clientIds.contains(
                      widget.clientId.toString().trim(),
                    );
                    final bool isPublicDoc = clientIds.contains(
                      "0",
                    ); // ✅ extra condition
                    if (!belongsToClient && !isPublicDoc) {
                      return const SizedBox.shrink(); // ❌ doc छुपा दो
                    }
                    // ✅ अब यहां आपका UI render होगा
                    return ListTile(
                      title: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //START CODE CATEGORY=="PHOTO"
                                category == "PHOTO"
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  children: [
                                    doc.docName == "Company Board"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Company Board"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .darkButton,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingcompanuBoard
                                                      ? const CircularProgressIndicator()
                                                      : companuBoard ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageCompanyBoard(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                      // pickImageCompanyBoard(ImageSource.camera);
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      companuBoard!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (companuBoard !=
                                                          null &&
                                                          companuBoardUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          companuBoardUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await companuBoard!
                                                              .delete();
                                                          setState(() {
                                                            companuBoard = null;
                                                            companuBoardUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Company Board"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "FE Selfie"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "FE Selfie"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingfeSelfie
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : feSelfie ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageFeSelfie(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      feSelfie!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (feSelfie !=
                                                          null &&
                                                          feSelfieUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          feSelfieUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await feSelfie!
                                                              .delete();
                                                          setState(() {
                                                            feSelfie = null;
                                                            feSelfieUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "FE Selfie"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Bill Desk"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Bill Desk"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingbillDesk
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : billDesk ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageBillDesk(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      billDesk!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (billDesk !=
                                                          null &&
                                                          billDeskUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          billDeskUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await billDesk!
                                                              .delete();
                                                          setState(() {
                                                            billDesk = null;
                                                            billDeskUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Bill Desk"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "FE Selfie With Person Met With Sound Box (Inside Shop)"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "FE Selfie With Person Met With Sound Box (Inside Shop)"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingfESelfieWithPerson
                                                      ? const CircularProgressIndicator()
                                                      : fESelfieWithPerson ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      //pickImageFESelfieWithPerson(ImageSource.camera, doc.docName);
                                                      await pickImageFESelfieWithPerson1(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      fESelfieWithPerson!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (fESelfieWithPerson !=
                                                          null &&
                                                          fESelfieWithPersonUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          fESelfieWithPersonUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await fESelfieWithPerson!
                                                              .delete();
                                                          setState(() {
                                                            fESelfieWithPerson =
                                                            null;
                                                            fESelfieWithPersonUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "FE Selfie With Person Met With Sound Box (Inside Shop)"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Front Door"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Front Door"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingfrontDoor
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : frontDoor ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageFrontDoor(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      frontDoor!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (frontDoor !=
                                                          null &&
                                                          frontDoorUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          frontDoorUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await frontDoor!
                                                              .delete();
                                                          setState(() {
                                                            frontDoor = null;
                                                            frontDoorUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Front Door"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Image of Person Met With Sound Box (Inside Shop)"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Image of Person Met With Sound Box (Inside Shop)"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingimageOfPersonMet
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : imageOfPersonMet ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageImageOfPersonMet(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      imageOfPersonMet!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (imageOfPersonMet !=
                                                          null &&
                                                          imageOfPersonMetUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          imageOfPersonMetUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await imageOfPersonMet!
                                                              .delete();
                                                          setState(() {
                                                            imageOfPersonMet =
                                                            null;
                                                            imageOfPersonMetUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Image of Person Met With Sound Box (Inside Shop)"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Bill DeskImage of Shop From OutsideBill Desk"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Bill DeskImage of Shop From OutsideBill Desk"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingbillDeskImageofShop
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : billDeskImageofShop ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageBillDeskImageofShop(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      billDeskImageofShop!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (billDeskImageofShop !=
                                                          null &&
                                                          billDeskImageofShopUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          billDeskImageofShopUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await billDeskImageofShop!
                                                              .delete();
                                                          setState(() {
                                                            billDeskImageofShop =
                                                            null;
                                                            billDeskImageofShopUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Bill DeskImage of Shop From OutsideBill Desk"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Image of Shop From Outside"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Image of Shop From Outside"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingimageofShopFromOutside
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : imageofShopFromOutside ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageImageofShopFromOutside(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      imageofShopFromOutside!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (imageofShopFromOutside !=
                                                          null &&
                                                          imageofShopFromOutsideUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          imageofShopFromOutsideUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await imageofShopFromOutside!
                                                              .delete();
                                                          setState(() {
                                                            imageofShopFromOutside =
                                                            null;
                                                            imageofShopFromOutsideUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Image of Shop From Outside"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Location Snap"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Location Snap"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadinglocationSnap
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : locationSnap ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageLocationSnap(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      locationSnap!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (locationSnap !=
                                                          null &&
                                                          locationSnapUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          locationSnapUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await locationSnap!
                                                              .delete();
                                                          setState(() {
                                                            locationSnap = null;
                                                            locationSnapUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Location Snap"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Name Plate"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Name Plate"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingnamePstatic
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : namePstatic ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageNamePstatic(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      namePstatic!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (namePstatic !=
                                                          null &&
                                                          namePstaticUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          namePstaticUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await namePstatic!
                                                              .delete();
                                                          setState(() {
                                                            namePstatic = null;
                                                            namePstaticUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Name Plate"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Photo"
                                        ? Column(
                                      children: [
                                        Container(
                                          height:
                                          MediaQuery
                                              .of(
                                            context,
                                          )
                                              .size
                                              .height /
                                              10,
                                          width: 500,
                                          color: Colors.white60,
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              Stack(
                                                children: [
                                                  Container(
                                                    height: 75,
                                                    width: 75,
                                                    decoration: BoxDecoration(
                                                      color: AppConstant
                                                          .iconColor,
                                                      border: Border.all(
                                                        color: Colors
                                                            .black,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                        5,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child:
                                                      isLoadingPhoto
                                                          ? const CircularProgressIndicator()
                                                          : photo ==
                                                          null
                                                          ? InkWell(
                                                        onTap: () async {
                                                          await pickImagePhoto1(
                                                            ImageSource.camera,
                                                            doc.docId,
                                                            doc.docName,
                                                          );
                                                        },
                                                        child: const Text(
                                                          "No image selected",
                                                          textAlign:
                                                          TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      )
                                                          : Container(
                                                        height:
                                                        73,
                                                        width:
                                                        73,
                                                        color:
                                                        Colors.white,
                                                        child: Image.file(
                                                          photo!,
                                                          fit:
                                                          BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: -2,
                                                    right: 2,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        try {
                                                          if (photo !=
                                                              null &&
                                                              photoUrl !=
                                                                  null) {
                                                            // 🔹 पहले Database से delete
                                                            bool
                                                            success = await deleteDocumentFromDB(
                                                              uid,
                                                              photoUrl!,
                                                            );

                                                            if (success) {
                                                              // 🔹 Local file भी delete
                                                              await photo!
                                                                  .delete();
                                                              setState(() {
                                                                photo =
                                                                null;
                                                                photoUrl =
                                                                null;
                                                              });
                                                              ScaffoldMessenger
                                                                  .of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    "✅ Deleted successfully",
                                                                  ),
                                                                ),
                                                              );
                                                            } else {
                                                              ScaffoldMessenger
                                                                  .of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    "❌ Failed to delete from DB",
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        } catch (
                                                        e
                                                        ) {
                                                          print(
                                                            "Error deleting file: $e",
                                                          );
                                                        }
                                                      },
                                                      child: Container(
                                                        decoration: const BoxDecoration(
                                                          color: Colors
                                                              .black,
                                                          shape: BoxShape
                                                              .circle,
                                                        ),
                                                        padding:
                                                        const EdgeInsets.all(
                                                          3,
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .delete_forever_outlined,
                                                          size: 18,
                                                          color: Colors
                                                              .white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Flexible(
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.all(
                                                    5.0,
                                                  ),
                                                  child: Text(
                                                    doc.docName,
                                                    textAlign:
                                                    TextAlign
                                                        .start,
                                                    softWrap: true,
                                                    overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                    maxLines: 3,
                                                    style: const TextStyle(
                                                      color: Colors
                                                          .black,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              Container(
                                                height:
                                                MediaQuery
                                                    .of(
                                                  context,
                                                )
                                                    .size
                                                    .height,
                                                color: Colors.white,
                                                width: 50,
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons
                                                        .add_circle,
                                                    color: AppConstant
                                                        .iconColor,
                                                    size: 28,
                                                  ),
                                                  onPressed: () {
                                                    _showAddDialog(
                                                      docName: doc
                                                          .docName,
                                                      docId:
                                                      doc.docId,
                                                    );
                                                  },
                                                ),
                                              ),

                                              // 🔹 Add Icon below the box
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                        : const SizedBox.shrink(),
                                    doc.docName == "Premises Interior"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Premises Interior"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingpremisesInterior
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : premisesInterior ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImagePremisesInterior(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      premisesInterior!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (premisesInterior !=
                                                          null &&
                                                          premisesInteriorUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          premisesInteriorUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await premisesInterior!
                                                              .delete();
                                                          setState(() {
                                                            premisesInterior =
                                                            null;
                                                            premisesInteriorUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Premises Interior"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "QR Code"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "QR Code"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingqRCode
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : qRCode ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageQRCode(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      qRCode!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (qRCode !=
                                                          null &&
                                                          qRCodeUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          qRCodeUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await qRCode!
                                                              .delete();
                                                          setState(() {
                                                            qRCode = null;
                                                            qRCodeUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "QR Code"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Stock"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: AppConstant
                                          .whiteBackColor,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Stock"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingstock
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : stock ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageStock(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      stock!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (stock !=
                                                          null &&
                                                          stockUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          stockUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await stock!.delete();
                                                          setState(() {
                                                            stock = null;
                                                            stockUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Stock"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Tent Card"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Tent Card"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingtentCard
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : tentCard ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageTentCard(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      tentCard!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (tentCard !=
                                                          null &&
                                                          tentCardUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          tentCardUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await tentCard!
                                                              .delete();
                                                          setState(() {
                                                            tentCard = null;
                                                            tentCardUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Tent Card"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Political Connections"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: 500,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Political Connections"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingpoliticalConnections
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : politicalConnections ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImagePoliticalConnections(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      politicalConnections!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (politicalConnections !=
                                                          null &&
                                                          politicalConnectionsUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          politicalConnectionsUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await politicalConnections!
                                                              .delete();
                                                          setState(() {
                                                            politicalConnections =
                                                            null;
                                                            politicalConnectionsUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Political Connections"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                  ],
                                )
                                    : SizedBox.shrink(),
                                //END CODE CATEGORY=="PHOTO"

                                //START CODE CATEGORY=="ID PROOF"
                                category == "ID PROOF"
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  children: [
                                    doc.docName ==
                                        "ID Proof of Person Met"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "ID Proof of Person Met"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingiDProofofPersonMet
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : iDProofofPersonMet ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageIDProofofPersonMet(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      iDProofofPersonMet!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (iDProofofPersonMet !=
                                                          null &&
                                                          iDProofofPersonMetUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          iDProofofPersonMetUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await iDProofofPersonMet!
                                                              .delete();
                                                          setState(() {
                                                            iDProofofPersonMet =
                                                            null;
                                                            iDProofofPersonMetUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "ID Proof of Person Met"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Pancard"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Pancard"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingpancard
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : pancard ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImagePancard(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      pancard!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (pancard !=
                                                          null &&
                                                          pancardUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          pancardUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await pancard!
                                                              .delete();
                                                          setState(() {
                                                            pancard = null;
                                                            pancardUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Pancard"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                  ],
                                )
                                    : SizedBox.shrink(),
                                //END CODE CATEGORY=="ID PROOF"

                                //START CODE CATEGORY=="OTHERS"
                                category == "OTHERS"
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  children: [
                                    doc.docName == "Annexure"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Annexure"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingAnnexure
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : annexure ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageAnnexure(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      annexure!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (annexure !=
                                                          null &&
                                                          annexureUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          annexureUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await annexure!
                                                              .delete();
                                                          setState(() {
                                                            annexure = null;
                                                            annexureUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Annexure"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Others"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Others"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingOthers
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : others ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageOthers(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      others!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (others !=
                                                          null &&
                                                          othersUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          othersUrl!,
                                                        );

                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await others!
                                                              .delete();
                                                          setState(() {
                                                            others = null;
                                                            othersUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Others"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "1 month Bank Statement"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "1 month Bank Statement"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoading1monthBankStatement
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : oneMonthBankStatement ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImage1monthBankStatement(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      oneMonthBankStatement!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (oneMonthBankStatement !=
                                                          null &&
                                                          oneMonthBankStatementUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          oneMonthBankStatementUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await oneMonthBankStatement!
                                                              .delete();
                                                          setState(() {
                                                            oneMonthBankStatement =
                                                            null;
                                                            oneMonthBankStatementUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "1 month Bank Statement"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Cancelled Cheque"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Cancelled Cheque"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingCancelledCheque
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : cancelledCheque ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageCancelledCheque(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      cancelledCheque!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (cancelledCheque !=
                                                          null &&
                                                          cancelledChequeUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          cancelledChequeUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await cancelledCheque!
                                                              .delete();
                                                          setState(() {
                                                            cancelledCheque =
                                                            null;
                                                            cancelledChequeUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Cancelled Cheque"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Company ID"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Company ID"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingCompanyID
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : companyID ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageCompanyID(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      companyID!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (companyID !=
                                                          null &&
                                                          companyIDUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          companyIDUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await companyID!
                                                              .delete();
                                                          setState(() {
                                                            companyID = null;
                                                            companyIDUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Company ID"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Completely Filled Job Sheet Image"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Completely Filled Job Sheet Image"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingCompletelyFilledJob
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : completelyFilledJob ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageCompletelyFilledJob(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      completelyFilledJob!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (completelyFilledJob !=
                                                          null &&
                                                          completelyFilledJobUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          completelyFilledJobUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await completelyFilledJob!
                                                              .delete();
                                                          setState(() {
                                                            completelyFilledJob =
                                                            null;
                                                            completelyFilledJobUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Completely Filled Job Sheet Image"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Due Diligence Form"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Due Diligence Form"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingDueDiligenceForm
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : dueDiligenceForm ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageDueDiligenceForm(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      dueDiligenceForm!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (dueDiligenceForm !=
                                                          null &&
                                                          dueDiligenceFormUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          dueDiligenceFormUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await dueDiligenceForm!
                                                              .delete();
                                                          setState(() {
                                                            dueDiligenceForm =
                                                            null;
                                                            dueDiligenceFormUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Due Diligence Form"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Form 26AS"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Form 26AS"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingForm26AS
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : form26AS ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageForm26AS(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      form26AS!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (form26AS !=
                                                          null &&
                                                          form26ASUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          form26ASUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await form26AS!
                                                              .delete();
                                                          setState(() {
                                                            form26AS = null;
                                                            form26ASUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Form 26AS"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Form 60"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Form 60"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .appSecondaryColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingForm60
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : form60 ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageForm60(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      form60!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (form60 !=
                                                          null &&
                                                          form60Url !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          form60Url!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await form60!
                                                              .delete();
                                                          setState(() {
                                                            form60 = null;
                                                            form60Url = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Form 60"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Gazette Certificate"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Gazette Certificate"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingGazetteCertificate
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : gazetteCertificate ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageGazetteCertificate(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      gazetteCertificate!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (gazetteCertificate !=
                                                          null &&
                                                          gazetteCertificateUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          gazetteCertificateUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await gazetteCertificate!
                                                              .delete();
                                                          setState(() {
                                                            gazetteCertificate =
                                                            null;
                                                            gazetteCertificateUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Gazette Certificate"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "GST Annex - A"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "GST Annex - A"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingGSTAnnexA
                                                      ? const CircularProgressIndicator()
                                                      : gSTAnnexA ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageGSTAnnexA(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      gSTAnnexA!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (gSTAnnexA !=
                                                          null &&
                                                          gSTAnnexAUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          gSTAnnexAUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await gSTAnnexA!
                                                              .delete();
                                                          setState(() {
                                                            gSTAnnexA = null;
                                                            gSTAnnexAUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "GST Annex - A"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.add_circle,
                                                color: Colors.black,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "GST Annex - B"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "GST Annex - B"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingGSTAnnexB
                                                      ? const CircularProgressIndicator()
                                                      : gSTAnnexB ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageGSTAnnexB(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      gSTAnnexB!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (gSTAnnexB !=
                                                          null &&
                                                          gSTAnnexBUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          gSTAnnexBUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await gSTAnnexB!
                                                              .delete();
                                                          setState(() {
                                                            gSTAnnexB = null;
                                                            gSTAnnexBUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "GST Annex - B"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Loan Agreement"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Loan Agreement"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .appSecondaryColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingLoanAgreement
                                                      ? const CircularProgressIndicator()
                                                      : loanAgreement ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageLoanAgreement(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      loanAgreement!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (loanAgreement !=
                                                          null &&
                                                          loanAgreementUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          loanAgreementUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await loanAgreement!
                                                              .delete();
                                                          setState(() {
                                                            loanAgreement =
                                                            null;
                                                            loanAgreementUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Loan Agreement"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Marriage Certificate"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Marriage Certificate"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingMarriageCertificate
                                                      ? const CircularProgressIndicator()
                                                      : marriageCertificate ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageMarriageCertificate(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      marriageCertificate!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (marriageCertificate !=
                                                          null &&
                                                          marriageCertificateUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          marriageCertificateUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await marriageCertificate!
                                                              .delete();
                                                          setState(() {
                                                            marriageCertificate =
                                                            null;
                                                            marriageCertificateUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Marriage Certificate"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Nach Only"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Nach Only"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingNachOnly
                                                      ? const CircularProgressIndicator()
                                                      : nachOnly ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageNachOnly(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      nachOnly!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (nachOnly !=
                                                          null &&
                                                          nachOnlyUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          nachOnlyUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await nachOnly!
                                                              .delete();
                                                          setState(() {
                                                            nachOnly = null;
                                                            nachOnlyUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Nach Only"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "OVD Declaration"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "OVD Declaration"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingOVDDeclaration
                                                      ? const CircularProgressIndicator()
                                                      : oVDDeclaration ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageOVDDeclaration(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      oVDDeclaration!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (oVDDeclaration !=
                                                          null &&
                                                          oVDDeclarationUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          oVDDeclarationUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await oVDDeclaration!
                                                              .delete();
                                                          setState(() {
                                                            oVDDeclaration =
                                                            null;
                                                            oVDDeclarationUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "OVD Declaration"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "POD Image"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "POD Image"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingPODImage
                                                      ? const CircularProgressIndicator()
                                                      : pODImage ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImagePODImage(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      pODImage!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (pODImage !=
                                                          null &&
                                                          pODImageUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          pODImageUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await pODImage!
                                                              .delete();
                                                          setState(() {
                                                            pODImage = null;
                                                            pODImageUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "POD Image"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Cheques (THREE)"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Cheques (THREE)"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingCheques
                                                      ? const CircularProgressIndicator()
                                                      : cheques ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageCheques(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      cheques!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (cheques !=
                                                          null &&
                                                          chequesUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          chequesUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await cheques!
                                                              .delete();
                                                          setState(() {
                                                            cheques = null;
                                                            chequesUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Cheques (THREE)"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Auth Sign Form"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Auth Sign Form"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingAuthSignForm
                                                      ? const CircularProgressIndicator()
                                                      : authSignForm ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageAuthSignForm(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      authSignForm!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (authSignForm !=
                                                          null &&
                                                          authSignFormUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          authSignFormUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await authSignForm!
                                                              .delete();
                                                          setState(() {
                                                            authSignForm = null;
                                                            authSignFormUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Auth Sign Form"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Shop & Establishment Certificate"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Shop & Establishment Certificate"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingShopEstablishmentCertificate
                                                      ? const CircularProgressIndicator()
                                                      : shopEstablishmentCertificate ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageShopEstablishmentCertificate(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      shopEstablishmentCertificate!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (shopEstablishmentCertificate !=
                                                          null &&
                                                          shopEstablishmentCertificateUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          shopEstablishmentCertificateUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await shopEstablishmentCertificate!
                                                              .delete();
                                                          setState(() {
                                                            shopEstablishmentCertificate =
                                                            null;
                                                            shopEstablishmentCertificateUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Shop & Establishment Certificate"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                  ],
                                )
                                    : SizedBox.shrink(),
                                //END CODE CATEGORY=="OTHERS"

                                //START CODE CATEGORY=="ADD PROOF"
                                category == "ADD PROOF"
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  children: [
                                    doc.docName == "Aadhaar Back"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Aadhaar Back"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingAadhaarBack
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : aadhaarBack ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageAadhaarBack(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      aadhaarBack!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (aadhaarBack !=
                                                          null &&
                                                          aadhaarBackUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          aadhaarBackUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await aadhaarBack!
                                                              .delete();
                                                          setState(() {
                                                            aadhaarBack = null;
                                                            aadhaarBackUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Aadhaar Back"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  12,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Aadhaar Front"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .start,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Aadhaar Front"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingAadhaarFront
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : aadhaarFront ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageAadhaarFront(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      aadhaarFront!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (aadhaarFront !=
                                                          null &&
                                                          aadhaarFrontUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          aadhaarFrontUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await aadhaarFront!
                                                              .delete();
                                                          setState(() {
                                                            aadhaarFront = null;
                                                            aadhaarFrontUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Aadhaar Front"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  12,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),

                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Allotment Letter"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Allotment Letter"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingAllotmentLetter
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : allotmentLetter ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageAllotmentLetter(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      allotmentLetter!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (allotmentLetter !=
                                                          null &&
                                                          allotmentLetterUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          allotmentLetterUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await allotmentLetter!
                                                              .delete();
                                                          setState(() {
                                                            allotmentLetter =
                                                            null;
                                                            allotmentLetterUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Allotment Letter"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Driving License ( card Type only)"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Driving License ( card Type only)"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingDrivingLicense
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : drivingLicense ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageDrivingLicense(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      drivingLicense!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (drivingLicense !=
                                                          null &&
                                                          drivingLicenseUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          drivingLicenseUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await drivingLicense!
                                                              .delete();
                                                          setState(() {
                                                            drivingLicense =
                                                            null;
                                                            drivingLicenseUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Driving License ( card Type only)"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Electricity Bill"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Electricity Bill"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingElectricityBill
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : electricityBill ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageElectricityBill(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      electricityBill!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (electricityBill !=
                                                          null &&
                                                          electricityBillUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          electricityBillUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await electricityBill!
                                                              .delete();
                                                          setState(() {
                                                            electricityBill =
                                                            null;
                                                            electricityBillUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Electricity Bill"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Gas Bill (Pipe line)"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Gas Bill (Pipe line)"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingGasBill
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : gasBill ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageGasBill(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      gasBill!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (gasBill !=
                                                          null &&
                                                          gasBillUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          gasBillUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await gasBill!
                                                              .delete();
                                                          setState(() {
                                                            gasBill = null;
                                                            gasBillUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Gas Bill (Pipe line)"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Land Line Bill"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Land Line Bill"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingLandLineBill
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : landLineBill ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageLandLineBill(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      landLineBill!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (landLineBill !=
                                                          null &&
                                                          landLineBillUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          landLineBillUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await landLineBill!
                                                              .delete();
                                                          setState(() {
                                                            landLineBill = null;
                                                            landLineBillUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Land Line Bill"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Maintainance Receipt"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Maintainance Receipt"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingMaintainanceReceipt
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : maintainanceReceipt ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageMaintainanceReceipt(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      maintainanceReceipt!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (maintainanceReceipt !=
                                                          null &&
                                                          maintainanceReceiptUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          maintainanceReceiptUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await maintainanceReceipt!
                                                              .delete();
                                                          setState(() {
                                                            maintainanceReceipt =
                                                            null;
                                                            maintainanceReceiptUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Maintainance Receipt"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Mobile Bill"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Mobile Bill"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingMobileBill
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : mobileBill ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageMobileBill(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      mobileBill!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (mobileBill !=
                                                          null &&
                                                          mobileBillUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          mobileBillUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await mobileBill!
                                                              .delete();
                                                          setState(() {
                                                            mobileBill = null;
                                                            mobileBillUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Mobile Bill"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Municipality Water Bill"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Municipality Water Bill"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingMunicipalityWaterBill
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : municipalityWaterBill ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageMunicipalityWaterBill(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      municipalityWaterBill!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (municipalityWaterBill !=
                                                          null &&
                                                          municipalityWaterBillUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          municipalityWaterBillUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await municipalityWaterBill!
                                                              .delete();
                                                          setState(() {
                                                            municipalityWaterBill =
                                                            null;
                                                            municipalityWaterBillUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Municipality Water Bill"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Passport"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Passport"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingPassport
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : passport ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImagePassport(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      passport!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (passport !=
                                                          null &&
                                                          passportUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          passportUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await passport!
                                                              .delete();
                                                          setState(() {
                                                            passport = null;
                                                            passportUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Passport"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Post Office SB Acc Statement"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Post Office SB Acc Statement"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingPostOfficeSB
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : postOfficeSB ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImagePostOfficeSB(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      postOfficeSB!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (postOfficeSB !=
                                                          null &&
                                                          postOfficeSBUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          postOfficeSBUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await postOfficeSB!
                                                              .delete();
                                                          setState(() {
                                                            postOfficeSB = null;
                                                            postOfficeSBUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Post Office SB Acc Statement"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Registered Rent Agreement + Owners E-Bill"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Registered Rent Agreement + Owners E-Bill"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingRegisteredRent
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : registeredRent ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageRegisteredRent(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      registeredRent!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (registeredRent !=
                                                          null &&
                                                          registeredRentUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          registeredRentUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await registeredRent!
                                                              .delete();
                                                          setState(() {
                                                            registeredRent =
                                                            null;
                                                            registeredRentUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Registered Rent Agreement + Owners E-Bill"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Registered Sales Deed"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Registered Sales Deed"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingRegisteredSales
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : registeredSales ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageRegisteredSales(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      registeredSales!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (registeredSales !=
                                                          null &&
                                                          registeredSalesUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          registeredSalesUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await registeredRent!
                                                              .delete();
                                                          setState(() {
                                                            registeredSales =
                                                            null;
                                                            registeredSalesUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Registered Sales Deed"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Rent Agreement"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Rent Agreement"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingRentAgreement
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : rentAgreement ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageRentAgreement(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      rentAgreement!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (rentAgreement !=
                                                          null &&
                                                          rentAgreementUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          rentAgreementUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await rentAgreement!
                                                              .delete();
                                                          setState(() {
                                                            rentAgreement =
                                                            null;
                                                            rentAgreementUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Rent Agreement"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Voter Card"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Voter Card"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingVoterCard
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : voterCard ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageVoterCard(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      voterCard!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (voterCard !=
                                                          null &&
                                                          voterCardUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          voterCardUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await voterCard!
                                                              .delete();
                                                          setState(() {
                                                            voterCard = null;
                                                            voterCardUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Voter Card"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                  ],
                                )
                                    : SizedBox.shrink(),
                                //END CODE CATEGORY=="ADD PROOF"

                                //START CODE CATEGORY=="INCOME PROOF"
                                category == "INCOME PROOF"
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  children: [
                                    doc.docName == "Credit Card Copy"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Credit Card Copy"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingCreditCardCopy
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : creditCardCopy ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageCreditCardCopy(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      creditCardCopy!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (creditCardCopy !=
                                                          null &&
                                                          creditCardCopyUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          creditCardCopyUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await creditCardCopy!
                                                              .delete();
                                                          setState(() {
                                                            creditCardCopy =
                                                            null;
                                                            creditCardCopyUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Credit Card Copy"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "ITR+Computation of Income"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "ITR+Computation of Income"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingITRComputation
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : iTRComputation ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageITRComputation(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      iTRComputation!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (iTRComputation !=
                                                          null) {
                                                        await iTRComputation!
                                                            .delete();
                                                        setState(
                                                              () {
                                                            iTRComputation =
                                                            null;
                                                          },
                                                        );
                                                        print(
                                                          "File deleted successfully!",
                                                        );
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "ITR+Computation of Income"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Latest Credit Card Statement"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Latest Credit Card Statement"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingLatestCreditCard
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : latestCreditCard ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageLatestCreditCard(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      latestCreditCard!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (latestCreditCard !=
                                                          null &&
                                                          latestCreditCardUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          latestCreditCardUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await latestCreditCard!
                                                              .delete();
                                                          setState(() {
                                                            latestCreditCard =
                                                            null;
                                                            latestCreditCardUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Latest Credit Card Statement"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName ==
                                        "Latest Salary Slip + 3 Months Salary Bank Statement"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Latest Salary Slip + 3 Months Salary Bank Statement"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingLatestSalarySlip
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : latestSalarySlip ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageLatestSalarySlip(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      latestSalarySlip!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (latestSalarySlip !=
                                                          null &&
                                                          latestSalarySlipUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          latestSalarySlipUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await latestSalarySlip!
                                                              .delete();
                                                          setState(() {
                                                            latestSalarySlip =
                                                            null;
                                                            latestSalarySlipUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Latest Salary Slip + 3 Months Salary Bank Statement"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Salary Slip"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Salary Slip"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingSalarySlip
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : salarySlip ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageSalarySlip(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      salarySlip!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (salarySlip !=
                                                          null &&
                                                          salarySlipUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          salarySlipUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await salarySlip!
                                                              .delete();
                                                          setState(() {
                                                            salarySlip = null;
                                                            salarySlipUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Salary Slip"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                  ],
                                )
                                    : SizedBox.shrink(),
                                //END CODE CATEGORY=="INCOME PROOF"

                                //START CODE CATEGORY=="ADD AND INCOME PROOF"
                                category == "ADD AND INCOME PROOF"
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  children: [
                                    doc.docName ==
                                        "3 Months Bank Statement"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "3 Months Bank Statement"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoading3MonthsBankStatement
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : threeMonthsBankStatement ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImage3MonthsBankStatement(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      threeMonthsBankStatement!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (threeMonthsBankStatement !=
                                                          null &&
                                                          threeMonthsBankStatementUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          threeMonthsBankStatementUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await threeMonthsBankStatement!
                                                              .delete();
                                                          setState(() {
                                                            threeMonthsBankStatement =
                                                            null;
                                                            threeMonthsBankStatementUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "3 Months Bank Statement"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Bank Passbook"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Bank Passbook"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingBankPassbook
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : bankPassbook ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageBankPassbook(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      bankPassbook!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (bankPassbook !=
                                                          null &&
                                                          bankPassbookUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          bankPassbookUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await bankPassbook!
                                                              .delete();
                                                          setState(() {
                                                            bankPassbook = null;
                                                            bankPassbookUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Bank Passbook"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                  ],
                                )
                                    : SizedBox.shrink(),
                                //END CODE CATEGORY=="ADD AND INCOME PROOF"

                                //START CODE CATEGORY=="ID AND ADD PROOF"
                                category == "ID AND ADD PROOF"
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  children: [
                                    doc.docName ==
                                        "Driving License ( card Type only)"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "Driving License ( card Type only)"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingDrivingLicenseAddProof
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : drivingLicenseAddProof ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageDrivingLicenseAddProof(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      drivingLicenseAddProof!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (drivingLicenseAddProof !=
                                                          null &&
                                                          drivingLicenseAddProofUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          drivingLicenseAddProofUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await drivingLicenseAddProof!
                                                              .delete();
                                                          setState(() {
                                                            drivingLicenseAddProof =
                                                            null;
                                                            drivingLicenseAddProofUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "Driving License ( card Type only)"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "NREGA Card"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName ==
                                              "NREGA Card"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingNREGACard
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : nREGACard ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImageNREGACard(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      nREGACard!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (nREGACard !=
                                                          null &&
                                                          nREGACardUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          nREGACardUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await nREGACard!
                                                              .delete();
                                                          setState(() {
                                                            nREGACard = null;
                                                            nREGACardUrl = null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName ==
                                              "NREGA Card"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                    doc.docName == "Passport"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Passport"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  isLoadingPassportAddProof
                                                      ? const CircularProgressIndicator(
                                                    // 🔹 Loader
                                                  )
                                                      : passportAddProof ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () async {
                                                      await pickImagePassportAddProof(
                                                        ImageSource.camera,
                                                        doc.docId,
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "No image selected",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.file(
                                                      passportAddProof!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                // Adjust these values to position the icon correctly
                                                right: 2,
                                                child: InkWell(
                                                  // Consider using InkWell for better tap feedback
                                                  onTap: () async {
                                                    try {
                                                      if (passportAddProof !=
                                                          null &&
                                                          passportAddProofUrl !=
                                                              null) {
                                                        // 🔹 पहले Database से delete
                                                        bool
                                                        success = await deleteDocumentFromDB(
                                                          uid,
                                                          passportAddProofUrl!,
                                                        );
                                                        if (success) {
                                                          // 🔹 Local file भी delete
                                                          await passportAddProof!
                                                              .delete();
                                                          setState(() {
                                                            passportAddProof =
                                                            null;
                                                            passportAddProofUrl =
                                                            null;
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "✅ Deleted successfully",
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "❌ Failed to delete from DB",
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    } catch (
                                                    e
                                                    ) {
                                                      print(
                                                        "Error deleting file: $e",
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black,
                                                      // Optional: background color for the icon
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                    padding:
                                                    EdgeInsets.all(
                                                      3,
                                                    ),
                                                    // Adjust padding as needed
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      size:
                                                      18,
                                                      color: Colors
                                                          .white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : SizedBox.shrink(),
                                          doc.docName == "Passport"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox(),
                                          Container(
                                            height: MediaQuery
                                                .of(
                                              context,
                                            )
                                                .size
                                                .height,
                                            color: Colors.white,
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: AppConstant
                                                    .iconColor,
                                                size: 28,
                                              ),
                                              onPressed: () {
                                                _showAddDialog(
                                                  docName:
                                                  doc.docName,
                                                  docId: doc.docId,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                  ],
                                )
                                    : SizedBox.shrink(),
                                //END CODE CATEGORY=="ID AND ADD PROOF"
                                //START CODE CATEGORY=="sIGNATURE"
                                category == "SIGNATURE"
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  children: [
                                    doc.docName == "Signature"
                                        ? Container(
                                      height:
                                      MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .height /
                                          10,
                                      width: MediaQuery
                                          .of(
                                        context,
                                      )
                                          .size
                                          .width,
                                      color: Colors.white60,
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          doc.docName == "Signature"
                                              ? Stack(
                                            children: [
                                              Container(
                                                height: 75,
                                                width: 75,
                                                decoration: BoxDecoration(
                                                  color: AppConstant
                                                      .iconColor,
                                                  border: Border.all(
                                                    color: Colors
                                                        .black,
                                                    width:
                                                    1.0,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child:
                                                  signatureImage ==
                                                      null
                                                      ? InkWell(
                                                    onTap: () {
                                                      _openSignaturePad(
                                                        doc.docName,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "Click to Signature",
                                                      textAlign: TextAlign
                                                          .center,
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                      : Container(
                                                    height:
                                                    73,
                                                    width:
                                                    73,
                                                    color:
                                                    Colors.white,
                                                    child: Image.memory(
                                                      signatureImage!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // 🔹 Delete Icon
                                              if (signatureImage !=
                                                  null)
                                                Positioned(
                                                  top: -2,
                                                  right: 2,
                                                  child: InkWell(
                                                    // Consider using InkWell for better tap feedback
                                                    onTap: () async {
                                                      try {
                                                        if (signatureImage !=
                                                            null &&
                                                            signatureImageUrl !=
                                                                null) {
                                                          // 🔹 पहले Database से delete
                                                          bool
                                                          success = await deleteDocumentFromDB(
                                                            uid,
                                                            signatureImageUrl!,
                                                          );
                                                          if (success) {
                                                            setState(
                                                                  () {
                                                                signatureImage =
                                                                null;
                                                                signatureImageUrl =
                                                                null;
                                                              },
                                                            );
                                                            ScaffoldMessenger
                                                                .of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  "✅ Deleted signatureImage",
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            ScaffoldMessenger
                                                                .of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  "❌ Failed to delete from DB",
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      } catch (
                                                      e
                                                      ) {
                                                        print(
                                                          "Error deleting file: $e",
                                                        );
                                                      }
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color:
                                                        Colors.black,
                                                        // Optional: background color for the icon
                                                        shape:
                                                        BoxShape.circle,
                                                      ),
                                                      padding:
                                                      EdgeInsets.all(
                                                        3,
                                                      ),
                                                      // Adjust padding as needed
                                                      child: Icon(
                                                        Icons
                                                            .delete_forever_outlined,
                                                        size:
                                                        18,
                                                        color:
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          )
                                              : const SizedBox.shrink(),
                                          doc.docName == "Signature"
                                              ? Flexible(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(
                                                5.0,
                                              ),
                                              child: Text(
                                                doc.docName,
                                                textAlign:
                                                TextAlign
                                                    .left,
                                                softWrap:
                                                true,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                                maxLines: 3,
                                                style: const TextStyle(
                                                  color: Colors
                                                      .black,
                                                  fontSize:
                                                  10,
                                                ),
                                              ),
                                            ),
                                          )
                                              : const SizedBox(),
                                        ],
                                      ),
                                    )
                                        : const SizedBox.shrink(),
                                  ],
                                )
                                    : const SizedBox.shrink(),
                                //END CODE CATEGORY=="sIGNATURE"
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),

      bottomSheet: collectedDocs.isEmpty
          ? null
          : AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        height: isCollapsed ? 60 : 250,
        // collapse / expand height
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 👇 Handle bar (tap to toggle)
              GestureDetector(
                onTap: () {
                  setState(() {
                    isCollapsed = !isCollapsed;
                  });
                },
                child: Center(
                  child: Container(
                    width: 50,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // 👇 Scrollable content only when expanded
              if (!isCollapsed)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: collectedDocs.length,
                            itemBuilder: (context, index) {
                              final doc = collectedDocs[index];
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        5,
                                      ),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        5,
                                      ),
                                      child: Image.file(
                                        File(doc.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () async {
                                        bool success =
                                        await deleteDocumentFromDB(
                                          uid,
                                          doc.pdfUrl,
                                        );

                                        if (success) {
                                          final file = File(doc.path);
                                          if (await file.exists())
                                            await file.delete();

                                          setState(() {
                                            collectedDocs.removeAt(index);
                                          });

                                          final prefs =
                                          await SharedPreferences.getInstance();
                                          final jsonList = collectedDocs
                                              .map((d) => d.toJson())
                                              .toList();
                                          await prefs.setString(
                                            "collectedDocs",
                                            jsonEncode(jsonList),
                                          );

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "✅ Deleted successfully",
                                              ),
                                              duration: Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              final prefs =
                              await SharedPreferences.getInstance();
                              await prefs.remove("collectedDocs");

                              setState(() {
                                collectedDocs.clear();
                              });

                              Get.snackbar(
                                "Document uploaded successfully.",
                                "Now, you can complete the lead.",
                                icon: Image.asset(
                                  "assets/logo/cmp_logo.png",
                                  height: 30,
                                  width: 30,
                                ),
                                shouldIconPulse: true,
                                backgroundColor:
                                AppConstant.snackBackColor,
                                colorText: AppConstant.snackFontColor,
                                snackPosition: SnackPosition.TOP,
                                borderRadius: 5,
                                margin: const EdgeInsets.all(12),
                                duration: const Duration(seconds: 3),
                              );

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstant.darkButton,
                              foregroundColor: AppConstant.whiteBackColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Text("Upload Document"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
