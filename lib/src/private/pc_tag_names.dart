// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

const List<String> pcTagNames = const [
  "1.2.840.113681",
  "1.2.840.113708.794.1.1.2.0",
  "ACUSON",
  "AEGIS_DICOM_2.00",
  "AGFA",
  "CAMTRONICS IP",
  "CAMTRONICS",
  "CARDIO-D.R. 1.0",
  "MRSC",
  "CMR42 CIRCLECVI",
  "DCMTK_ANONYMIZER",
  "DIDI TO PCR 1.1",
  "DIGISCAN IMAGE",
  "DLX_EXAMS_01",
  "DLX_PATNT_01",
  "DLX_SERIE_01",
  "ELSCINT1",
  "FDMS 1.0",
  "GEMS_PARM_01",
  "FFP DATA",
  "GE ??? From Adantage Review CS",
  "GEMS_ACQU_01",
  "GEMS_ACRQA_1.0 BLOCK1",
  "GEMS_ACRQA_1.0 BLOCK2",
  "GEMS_ACRQA_1.0 BLOCK3",
  "GEMS_ACRQA_2.0 BLOCK1",
  "GEMS_ACRQA_2.0 BLOCK2",
  "GEMS_ACRQA_2.0 BLOCK3",
  "GEMS_ADWSoft_3D1",
  "GEMS_ADWSoft_DPO",
  "GEMS_CTHD_01",
  "GEMS_DRS_1",
  "GEMS_GENIE_1",
  "GEMS_GNHD_01",
  "GEMS_IDEN_01",
  "GEMS_IMAG_01",
  "GEMS_IMPS_01",
  "GEMS_RELA_01",
  "SIEMENS RA GEN",
  "GEMS_SENO_02",
  "GEMS_YMHD_01",
  "GE_GENESIS_REV3.0",
  "SVISION",
  "GEMS_STDY_01",
  "GEMS_SERS_01",
  "INTELERAD MEDICAL SYSTEMS",
  "INTEGRIS 1.0",
  "ISG shadow",
  "ISI",
  "MERGE TECHNOLOGIES, INC.",
  "OCULUS Optikgeraete GmbH",
  "PAPYRUS 3.0",
  "PAPYRUS",
  "Philips Imaging DD 001",
  "Philips MR Imaging DD 001",
  "Philips MR Imaging DD 005",
  "PHILIPS MR R5.5/PART",
  "PHILIPS MR R5.6/PART",
  "PHILIPS MR SPECTRO;1",
  "PHILIPS MR",
  "PHILIPS MR/LAST",
  "PHILIPS MR/PART",
  "PHILIPS-MR-1",
  "Picker NM Private Group",
  "SIEMENS CM VA0  ACQU",
  "SIEMENS CM VA0  CMS",
  "SIEMENS CM VA0  LAB",
  "SIEMENS CSA NON-IMAGE",
  "SIEMENS CT VA0  COAD",
  "SIEMENS CSA HEADER",
  "SIEMENS CT VA0  GEN",
  "SIEMENS CT VA0  IDE",
  "SIEMENS CT VA0  ORI",
  "SIEMENS CT VA0  OST",
  "SIEMENS CT VA0  RAW",
  "SIEMENS DICOM",
  "SIEMENS DLR.01",
  "SIEMENS ISI",
  "SIEMENS MED DISPLAY",
  "SIEMENS MED HG",
  "SIEMENS MED MG",
  "SIEMENS MED",
  "SIEMENS MEDCOM HEADER",
  "SIEMENS MR VA0  COAD",
  "SIEMENS MEDCOM HEADER2",
  "SIEMENS MEDCOM OOG",
  "SIEMENS MR VA0  GEN",
  "SIEMENS MR VA0  RAW",
  "SIEMENS NUMARIS II",
  "SIEMENS RA PLANE A",
  "SIEMENS RA PLANE B",
  "SIEMENS RIS",
  "SIEMENS SMS-AX  ACQ 1.0",
  "SIEMENS SMS-AX  ORIGINAL IMAGE INFO 1.0",
  "SIEMENS SMS-AX  QUANT 1.0",
  "SIEMENS SMS-AX  VIEW 1.0",
  "SIENET",
  "SPI RELEASE 1",
  "SPI",
  "SPI-P Release 1",
  "SPI-P Release 1;1",
  "SPI-P Release 1;2",
  "SPI-P Release 1;3",
  "SPI-P Release 2;1",
  "SPI-P-GV-CT Release 1",
  "SPI-P-PCR Release 2",
  "SPI-P-Private-CWS Release 1",
  "SPI-P-Private-DCI Release 1",
  "SPI-P-Private_CDS Release 1",
  "SPI-P-Private_ICS Release 1",
  "SPI-P-Private_ICS Release 1;1",
  "SPI-P-Private_ICS Release 1;2",
  "SPI-P-Private_ICS Release 1;3",
  "SPI-P-Private_ICS Release 1;4",
  "SPI-P-Private_ICS Release 1;5",
  "SPI-P-XSB-DCI Release 1",
  "Silhouette Annot V1.0",
  "Silhouette Graphics Export V1.0",
  "Silhouette Line V1.0",
  "Silhouette ROI V1.0",
  "Silhouette Sequence Ids V1.0",
  "Silhouette V1.0",
  "SONOWAND AS",
  "TOSHIBA_MEC_1.0",
  "TOSHIBA_MEC_CT_1.0",
  "ACUSON:1.2.840.113680.1.0:0910",
  "ACUSON:1.2.840.113680.1.0:7f10",
  "AGFA-AG_HPState",
  "ACUSON:1.2.840.113680.1.0:7ffe",
  "AgilityRuntime",
  "AGFA_ADC_Compact",
  "Agfa ADC NX",
  "AGFA PACS Archive Mirroring 1.0",
  "MITRA PRESENTATION 1.0",
  "MITRA OBJECT DOCUMENT 1.0",
  "MITRA MARKUP 1.0",
  "MITRA LINKED ATTRIBUTES 1.0",
  "MITRA OBJECT UTF8 ATTRIBUTES 1.0",
  "MITRA OBJECT ATTRIBUTES 1.0",
  "AgilityOverlay",
  "AGFA KOSD 1.0",
  "agfa/displayableImages",
  "agfa/xeroverse",
  "Camtronics image level data",
  "QCA Results",
  "GEMS_PETD_01",
  "GEMS_DL_PATNT_01",
  "GEMS_DL_STUDY_01",
  "GEMS_DL_SERIES_01",
  "GEMS_DL_IMG_01",
  "GEMS_XR3DCAL_01",
  "Mayo/IBM Archive Project",
  "GEMS_3D_INTVL_01",
  "GEMS_DL_FRAME_01",
  "GEMS_ADWSoft_DPO1",
  "GEMS_AWSoft_SB1",
  "GEMS_AWSOFT_CD1",
  "GEMS_HELIOS_01",
  "GEMS_3DSTATE_001",
  "GEMS_IQTB_IDEN_47",
  "GEMS_CT_HINO_01",
  "GEIIS",
  "GEMS_CT_VES_01",
  "AMI Annotations_01",
  "AMI Annotations_02",
  "AMI Sequence Annotations_01",
  "AMI Sequence Annotations_02",
  "GEMS_CT_CARDIAC_001",
  "AMI Sequence AnnotElements_01",
  "AMI ImageTransform_01",
  "AMI ImageContextExt_01",
  "Applicare/RadWorks/Version 5.0",
  "Applicare/RadWorks/Version 6.0/Summary",
  "http://www.gemedicalsystems.com/it_solutions/rad_pacs/",
  "Applicare/Print/Version 5.1",
  "Applicare/RadWorks/Version 6.0",
  "GEIIS PACS",
  "GEMS_GDXE_FALCON_04",
  "GEMS_FALCON_03",
  "GEMS_SEND_02",
  "GEMS_GDXE_ATHENAV2_INTERNAL_USE",
  "GEMS_Ultrasound_ImageGroup_001",
  "GEMS_Ultrasound_ExamGroup_001",
  "GEMS_Ultrasound_MovieGroup_001",
  "KRETZ_US",
  "QUASAR_INTERNAL_USE",
  "APEX_PRIVATE",
  "GEMS_XELPRV_01",
  "REPORT_FROM_APP",
  "GEMS_VXTL_USERDATA_01",
  "DL_INTERNAL_USE",
  "GEMS_LUNAR_RAW",
  "GE_GROUP",
  "GEMS_IT_US_REPORT",
  "Applicare/Workflow/Version 1.0",
  "GEHC_CT_ADVAPP_001",
  "GE LUT Asymmetry Parameter",
  "Applicare/Centricity Radiology Web/Version 1.0",
  "Applicare/Centricity Radiology Web/Version 2.0",
  "GEMS-IT/Centricity RA600/7.0",
  "AMI StudyExtensions_01",
  "RadWorksTBR",
  "Applicare/RadStore/Version 1.0",
  "http://www.gemedicalsystems.com/it_solutions/orthoview/2.1",
  "http://www.gemedicalsystems.com/it_solutions/bamwallthickness/1.0",
  "AMI ImageContext_01",
  "GEMS_FUNCTOOL_01",
  "Harmony R1.0",
  "Harmony R1.0 C2",
  "Harmony R1.0 C3",
  "Harmony R2.0",
  "Hologic",
  "LODOX_STATSCAN",
  "SCHICK TECHNOLOGIES - Change List Creator ID",
  "SCHICK TECHNOLOGIES - Note List Creator ID",
  "SCHICK TECHNOLOGIES - Change Item Creator ID",
  "SCHICK TECHNOLOGIES - Image Security Creator ID",
  "2.16.840.1.114059.1.1.6.1.50.1",
  "STENTOR",
  "MMCPrivate",
  "Canon Inc.",
  "SECTRA_Ident_01",
  "SECTRA_ImageInfo_01",
  "SECTRA_OverlayInfo_01",
  "BioPri",
  "Silhouette VRS 3.0",
  "ADAC_IMG",
  "Hipaa Private Creator",
  "LORAD Selenia",
  "HOLOGIC, Inc.",
  "1.2.840.113663.1",
  "MeVis BreastCare",
  "Viewing Protocol",
  "Mortara_Inc",
  "SEGAMI_HEADER",
  "SEGAMI MIML",
  "SEGAMI__PAGE",
  "SEGAMI__MEMO",
  "MedIns HP Extensions",
  "MEDIFACE",
  "Image (ID, Version, Size, Dump, GUID)",
  "ObjectModel (ID, Version, Place, PlaceDescription)",
  "INFINITT_FMX",
  "BrainLAB_Conversion",
  "BrainLAB_PatientSetup",
  "BrainLAB_BeamProfile",
  "V1",
  "Voxar 2.16.124.113543.6003.1999.12.20.12.5.0",
  "Kodak Image Information",
  "NQLeft",
  "MAROTECH Inc.",
  "BRIT Systems, Inc.",
  "MDS NORDION OTP ANATOMY MODELLING",
  "Imaging Dynamics Company Ltd.",
  "Sound Technologies",
  "A.L.I. Technologies, Inc.",
  "NUD_PRIVATE",
  "IDEXX",
  "WG12 Supplement 43",
  "HMC - CT - ID",
  "SET WINDOW",
  "Vital Images SW 3.4",
  "PI Private Block (0781:3000 - 0781:30FF)",
  "Riverain Medical",
  "INTELERAD MEDICAL SYSTEMS INTELEVIEWER",
  "DR Systems, Inc.",
  "ETIAM DICOMDIR",
  "TERARECON AQUARIUS",
  "EMAGEON STUDY HOME",
  "EMAGEON JPEG2K INFO",
  "RadWorksMarconi",
  "MeVis eatDicom",
  "MeVis eD: Timepoint Information",
  "MeVis eD: Absolute Temporal Positions",
  "MeVis eD: Geometry Information",
  "MeVis eD: Slice Information",
  "ShowcaseAppearance",
  "NQHeader",
  "NQRight",
  "VEPRO VIF 3.0 DATA",
  "VEPRO VIM 5.0 DATA",
  "VEPRO BROKER 1.0",
  "VEPRO BROKER 1.0 DATA REPLACE",
  "VEPRO DICOM TRANSFER 1.0",
  "VEPRO DICOM RECEIVE DATA 1.0",
  "KONICA1.0",
  "CTP",
  "dcm4che/archive",
  "IMS s.r.l. Biopsy Private Code",
  "IMS s.r.l. Mammography Private Code",
  "DZDICOM 4.3.0",
  "FOEM 1.0",
  "Visus Change",
  "SYNARC_1.0",
  "PixelMed Publishing",
  "METAEMOTION GINKGO",
  "METAEMOTION GINKGO RETINAL",
  "PMOD_1",
  "PMOD_GENPET",
  "ULTRAVISUAL_TAG_SET1",
  "MATAKINA_10",
  "PM",
  "Biospace Med : EOS Tag",
  "PRIVATE_CODE_STRING_0019",
  "PRIVATE_CODE_STRING_0021",
  "PRIVATE_CODE_STRING_1001",
  "CAD Sciences",
  "PRIVATE_CODE_STRING_1003",
  "PRIVATE_CODE_STRING_3007",
  "PRIVATE_CODE_STRING_300B",
  "INSTRU_PRIVATE_IDENT_CODE",
  "SCANORA_PRIVATE_IDENT_CODE",
  "NNT",
  "iCAD PK",
  "iCAD PK Study",
  "TomTec",
  "CARESTREAM IMAGE INFORMATION",
  "Carestream Health TIFF",
  "RamSoft File Kind Identifier",
  "RamSoft Custom Report Identifier",
  "RamSoft Race Identifier",
  "MDDX",
  "QTUltrasound",
  "BioscanMedisoScivisNanoSPECT",
  "MEDISO-1",
  "SCIVIS-1",
  "Brainlab-S9-History",
  "Brainlab-S32-SO",
  "Brainlab-S23-ProjectiveFusion",
  "PHILIPS MR/PART 12",
  "PHILIPS MR/PART 7",
  "SPI-P-CTBE Release 1",
  "SPI-P-Private-DiDi Release 1",
  "SPI-P-XSB-VISUB Release 1",
  "PHILIPS MR/PART 6",
  "SPI-P-CTBE-Private Release 1",
  "PMS-THORA-5.1",
  "Philips PET Private Group",
  "Philips Imaging DD 124",
  "Philips Imaging DD 129",
  "Philips Imaging DD 002",
  "Philips X-ray Imaging DD 001",
  "Philips MR Imaging DD 003",
  "Philips MR Imaging DD 004",
  "Philips MR Imaging DD 002",
  "Philips EV Imaging DD 022",
  "Philips RAD Imaging DD 001",
  "Philips RAD Imaging DD 097",
  "Philips US Imaging DD 033",
  "Philips US Imaging DD 066",
  "Philips US Imaging DD 109",
  "Philips US Imaging DD 034",
  "Philips US Imaging DD 035",
  "Philips US Imaging DD 038",
  "Philips US Imaging DD 039",
  "Philips US Imaging DD 040",
  "Philips US Imaging DD 041",
  "Philips US Imaging DD 048",
  "Philips US Imaging DD 113",
  "Philips US Imaging DD 037",
  "Philips US Imaging DD 017",
  "Philips US Imaging DD 043",
  "Philips US Imaging DD 021",
  "Philips US Imaging DD 065",
  "Philips US Imaging DD 036",
  "Philips US Imaging DD 042",
  "Philips US Imaging DD 046",
  "Philips US Imaging DD 023",
  "Philips US Imaging DD 045",
  "Philips Imaging DD 067",
  "Philips Imaging DD 070",
  "Philips Imaging DD 065",
  "Philips Imaging DD 073",
  "Philips NM Private Group",
  "PHILIPS NM -Private",
  "PHILIPS XCT -Private",
  "Picker MR Private Group",
  "SIEMENS SYNGO INSTANCE MANIFEST",
  "SIEMENS MED NM",
  "SIEMENS SYNGO INDEX SERVICE",
  "SIEMENS AX INSPACE_EP",
  "SIEMENS MR DATAMAPPING ATTRIBUTES",
  "ESOFT_DICOM_ECAT_OWNERCODE",
  "Siemens: Thorax/Multix FD Version",
  "SIEMENS_FLCOMPACT_VA01A_PROC",
  "SIEMENS DFR.01 ORIGINAL",
  "SIEMENS DFR.01 MANIPULATED",
  "SIEMENS MED SP DXMG WH AWS 1",
  "SIEMENS Selma",
  "SIEMENS SIENET",
  "SIEMENS MED SMS USG ANTARES",
  "SIEMENS SYNGO VOLUME",
  "Siemens Ultrasound Miscellaneous",
  "Siemens: Thorax/Multix FD Lab Settings",
  "SIEMENS MED SMS USG S2000",
  "SIEMENS MED ECAT FILE INFO",
  "Siemens: Thorax/Multix FD Post Processing",
  "KINETDX_GRAPHICS",
  "KINETDX",
  "syngoDynamics",
  "Siemens: Thorax/Multix FD Image Stamp",
  "Siemens: Thorax/Multix FD Raw Image Settings",
  "SIEMENS SYNGO ENHANCED IDATASET API",
  "SIEMENS SYNGO FUNCTION ASSIGNMENT",
  "SHS MagicView 300",
  "SIEMENS MED MAMMO",
  "SIEMENS MED DISPLAY 0000",
  "SIEMENS MED DISPLAY 0001",
  "SIEMENS SYNGO TIME POINT SERVICE",
  "SIEMENS SYNGO ADVANCED PRESENTATION",
  "SIEMENS SYNGO FRAME SET",
  "SIEMENS SYNGO PRINT SERVICE",
  "SIEMENS IKM CKS LUNGCAD BMK",
  "SIEMENS IKM CKS CXRCAD FINDINGS",
  "SIEMENS SYNGO SOP CLASS PACKING",
  "SIEMENS CSA ENVELOPE",
  "SIEMENS CSA REPORT",
  "SIEMENS SYNGO WORKFLOW",
  "SIEMENS MI RWVM SUV",
  "SIEMENS WH SR 1.0",
  "SIEMENS MED PT",
  "SIEMENS SYNGO REGISTRATION",
  "SIEMENS SYNGO OBJECT GRAPHICS",
  "SIEMENS MED PT WAVEFORM",
  "SIEMENS SYNGO LAYOUT PROTOCOL",
  "SIEMENS SYNGO EVIDENCE DOCUMENT DATA",
  "syngoDynamics_Reporting",
  "SIEMENS MR N3D",
  "SIEMENS SYNGO ENCAPSULATED DOCUMENT DATA",
  "SIEMENS SYNGO 3D FUSION MATRIX",
  "SIEMENS Ultrasound SC2000",
  "SIEMENS SYNGO DATA PADDING",
  "SIEMENS MR HEADER",
  "SIEMENS SERIES SHADOW ATTRIBUTES",
  "SIEMENS IMAGE SHADOW ATTRIBUTES",
  "SIEMENS MR IMA",
  "SIEMENS MR PHOENIX ATTRIBUTES",
  "SIEMENS MR SDS 01",
  "SIEMENS MR MRS 05",
  "SIEMENS MR EXTRACTED CSA HEADER",
  "SIEMENS MR SDI 02",
  "SIEMENS MR CM 03",
  "SIEMENS MR PS 04",
  "SIEMENS MR FOR 06",
  "SIEMENS CT APPL DATASET",
  "SIEMENS CT APPL EVIDENCEDOCUMENT",
  "SIEMENS CT APPL MEASUREMENT",
  "SIEMENS CT APPL PRESENTATION",
  "SIEMENS CT APPL TMP DATAMODEL",
  "SIEMENS MED SMS USG ANTARES 3D VOLUME",
  "SIEMENS MED SMS USG S2000 3D VOLUME",
  "SIEMENS MED OCS BEAM DISPLAY INFO",
  "SIEMENS MED OCS PUBLIC RT PLAN ATTRIBUTES",
  "SIEMENS MED OCS SS VERSION INFO",
  "BioPri3D",
  "PMI Private Calibration Module Version 2.0",
  "POLYTRON-SMS 2.5",
  "SIEMENS MED SYNGO RT",
  "SIEMENS SYNGO ULTRA-SOUND TOYON DATA STREAMING",
  "SIEMENS Ultrasound S2000",
  "SMIL_PB79",
  "SMIO_PB7B",
  "SMIO_PB7D",
  "TOSHIBA_MEC_OT3",
  "TOSHIBA MDW NON-IMAGE",
  "TOSHIBA MDW HEADER",
  "TOSHIBA COMAPL HEADER",
  "TOSHIBA COMAPL OOG",
  "PMTF INFORMATION DATA",
  "TOSHIBA_MEC_CT3",
  "TOSHIBA ENCRYPTED SR DATA",
  "TOSHIBA_SR",
  "TOSHIBA_MEC_XA3",
  "GE_YMS_NJ001",
  "GEMS_PATI_01",
  "GEMS_CT_FLRO_01",
  "GEMS_0039",
  "GEMS_HINO_CT_01",
  "BrainWave: 1.2.840.113819.3",
  "GEMS_MR_RAW_01",
  "TOSHIBA_MEC_MR3"
];
