// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:green_books/navigation/navigation_wrapper.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:green_books/widgets/navigation/icons_header.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:green_books/widgets/common/text_fields.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:green_books/styles/custom_button.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:green_books/widgets/common/dropdown_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:green_books/pages/centers/nearby_centers.dart';

class ScanAndUploadPage extends StatefulWidget {
  const ScanAndUploadPage({super.key});

  @override
  State<ScanAndUploadPage> createState() => _ScanAndUploadPageState();
}

class _ScanAndUploadPageState extends State<ScanAndUploadPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _academicFields = [
    'Chemistry',
    'Physics',
    'Mathematics',
    'Biology',
    'Computer Science',
    'Engineering',
    'Economics',
    'Medicine',
    'Law',
    'Arts',
    'History',
    'Geography',
    'Psychology',
    'Philosophy',
    'Religion',
    'Literature',
    'Arabic Studies',
    'French Studies',
    'German Studies',
    'Italian Studies',
    'Spanish Studies',
    'Others',
  ];

  String? _selectedField;
  String? _aiPredictedField;
  bool _allowManualSelection = false;
  final String _postStatus = 'Donate';

  File? _pdfFile;
  int? _pageCount;
  bool _isUploading = false;
  bool _isClassifying = false;
  bool _isDocValid = true;

  List<String> _locationOptions = [];
  String? _selectedLocation;
  bool _isFetchingLocations = false;

  @override
  void initState() {
    super.initState();
    _fetchNearbyLocations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchNearbyLocations() async {
    setState(() => _isFetchingLocations = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      final places = await _fetchNearbyPlaceNames(latLng);
      setState(() {
        _locationOptions = places;
        _selectedLocation = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location fetch failed: $e')));
    } finally {
      setState(() => _isFetchingLocations = false);
    }
  }

  Future<List<String>> _fetchNearbyPlaceNames(LatLng location) async {
    const apiKey = 'AIzaSyB715cm57Fb-nuhUYxW-YSTwi31mGKSGso';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&radius=3000&type=establishment&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Failed to load places');

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>?) ?? [];

    return results
        .map((place) => place['name'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
  }

  Future<void> _uploadPost() async {
    final user = FirebaseAuth.instance.currentUser;
    final price = double.tryParse(_priceController.text.trim());

    if (user == null ||
        _titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _selectedLocation == null ||
        (_postStatus == 'Sell' && (price == null || price <= 0)) ||
        _selectedField == null ||
        _pdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields correctly')),
      );
      return;
    }

    setState(() => _isUploading = true);
    final postId = FirebaseFirestore.instance.collection('posts').doc().id;
    try {
      final ref = FirebaseStorage.instance.ref('posts/${user.uid}/$postId.pdf');
      final snapshot = await ref.putFile(_pdfFile!);
      final pdfUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('posts').doc(postId).set({
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'location': _selectedLocation,
        'academicField': _selectedField,
        'status': _postStatus,
        'fulfilled': false,
        'fulfilledWith': null,
        'fulfilledAt': null,
        'pdfUrl': pdfUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'price': _postStatus == 'Sell' ? price : null,
        'pageCount': _pageCount ?? 0,
      });

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => NavigationWrapper()));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      _pageCount = await _getPdfPageCount(file);
      setState(() {
        _pdfFile = file;
        _isDocValid = true;
      });
      await _classifyPDF(file);
    }
  }

  Future<void> _scanPDF() async {
    final scannedPaths = await CunningDocumentScanner.getPictures();
    if (scannedPaths == null || scannedPaths.isEmpty) return;

    final pdf = pw.Document();
    for (final path in scannedPaths) {
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(image))));
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    _pageCount = await _getPdfPageCount(file);
    setState(() {
      _pdfFile = file;
      _isDocValid = true;
    });
    await _classifyPDF(file);
  }

  Future<int?> _getPdfPageCount(File file) async {
    try {
      final pdfDoc = PdfDocument(inputBytes: await file.readAsBytes());
      final count = pdfDoc.pages.count;
      pdfDoc.dispose();
      return count;
    } catch (_) {
      return null;
    }
  }

  Future<void> _classifyPDF(File file) async {
    setState(() => _isClassifying = true);
    try {
      final canBeReused = await _verifyDocumentPurpose(file);
      if (!canBeReused) {
        setState(() => _isDocValid = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This document is not suitable for academic reuse. Recycling is advised.',
            ),
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          final navWrapperState = NavigationWrapper.of(context);
          if (navWrapperState != null) {
            navWrapperState.navigateToTab(AppTab.centers);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const NearbyCenters()),
            );
          }
        });
        return;
      }

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
      );
      final response = await model.generateContent([
        Content.multi([
          TextPart(
            'Classify this academic document into one of the following fields: ${_academicFields.join(", ")}. Respond with only the field name.',
          ),
          InlineDataPart('application/pdf', await file.readAsBytes()),
        ]),
      ]);

      final prediction = response.text?.trim();
      if (prediction != null && _academicFields.contains(prediction)) {
        setState(() {
          _aiPredictedField = prediction;
          _selectedField = prediction;
          _allowManualSelection = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI could not classify the document.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI classification failed: $e')));
    } finally {
      setState(() => _isClassifying = false);
    }
  }

  Future<bool> _verifyDocumentPurpose(File file) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
      );
      final response = await model.generateContent([
        Content.multi([
          TextPart(
            'Can this PDF document be read by a human, and reused strictly for studying on of these fields ${_academicFields.join(", ")} by other students? Answer only "Yes" or "No".',
          ),
          InlineDataPart('application/pdf', await file.readAsBytes()),
        ]),
      ]);

      final answer = response.text?.toLowerCase().trim();
      return answer == 'yes';
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const IconsHeader(title: 'Create Post'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  MyTextField(controller: _titleController, hintText: 'Title'),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: _descController,
                    hintText: 'Description',
                  ),
                  if (_postStatus == 'Sell') ...[
                    const SizedBox(height: 10),
                    MyTextField(
                      controller: _priceController,
                      hintText: 'Price in EGP',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  MyDropdownField(
                    items: _isFetchingLocations ? [] : _locationOptions,
                    value: _selectedLocation,
                    onChanged: _isFetchingLocations
                        ? (_) {}
                        : (value) => setState(() => _selectedLocation = value),
                    hintText: _isFetchingLocations
                        ? 'Loading nearby locations...'
                        : 'Select location',
                  ),
                  const SizedBox(height: 10),
                  if (_aiPredictedField != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _allowManualSelection
                            ? MyDropdownField(
                                items: _academicFields,
                                value: _selectedField,
                                onChanged: (value) =>
                                    setState(() => _selectedField = value),
                                hintText: 'Select academic field',
                              )
                            : MyTextField(
                                controller: TextEditingController(
                                  text: _aiPredictedField,
                                ),
                                hintText: 'Predicted Academic Field',
                                readOnly: true,
                                enabled: false,
                              ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _allowManualSelection,
                              onChanged: (val) =>
                                  setState(() => _allowManualSelection = val!),
                            ),
                            const Text('Edit predicted field'),
                          ],
                        ),
                      ],
                    )
                  else
                    MyDropdownField(
                      items: _academicFields,
                      value: _selectedField,
                      onChanged: (value) =>
                          setState(() => _selectedField = value),
                      hintText: 'Select academic field',
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickPDF,
                          icon: const Icon(Icons.attach_file_rounded),
                          label: const Text('Pick PDF'),
                          style: CustomButtonStyles.uploadButtonStyle(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _scanPDF,
                          icon: const Icon(Icons.document_scanner_rounded),
                          label: const Text('Scan PDF'),
                          style: CustomButtonStyles.uploadButtonStyle(),
                        ),
                      ),
                    ],
                  ),
                  if (_pdfFile != null || _isClassifying) ...[
                    const SizedBox(height: 12),
                    if (_pdfFile != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PDF: ${_pdfFile!.path.split('/').last}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          if (_pageCount != null)
                            Text(
                              '$_pageCount pages',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed:
                          (_isUploading ||
                              _isClassifying ||
                              _pdfFile == null ||
                              !_isDocValid)
                          ? null
                          : _uploadPost,
                      icon: Icon(
                        _isClassifying
                            ? Icons.hourglass_empty
                            : Icons.upload_file_rounded,
                      ),
                      label: Text(
                        _isClassifying
                            ? 'Classifying PDF...'
                            : !_isDocValid
                            ? 'Invalid Document'
                            : 'Upload',
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.black54,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
