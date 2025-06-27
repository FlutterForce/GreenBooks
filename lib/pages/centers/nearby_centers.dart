import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:green_books/widgets/common/text_fields.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:green_books/widgets/nearby/center_service.dart';
import 'package:green_books/widgets/navigation/icons_header.dart';
import 'package:green_books/styles/custom_button.dart'; // adjust the path as needed

class NearbyCenters extends StatelessWidget {
  const NearbyCenters({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      body: const SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconsHeader(title: 'Nearby Centers'),
            Expanded(child: CenterMap()),
          ],
        ),
      ),
    );
  }
}

class CenterMap extends StatefulWidget {
  const CenterMap({super.key});

  @override
  State<CenterMap> createState() => _CenterMapState();
}

class _CenterMapState extends State<CenterMap> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _loading = true;
  String _errorMessage = '';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _initLocationAndMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndMarkers() async {
    try {
      final position = await _determinePosition();
      if (!mounted) return;

      final newPosition = LatLng(position.latitude, position.longitude);
      final fetchedMarkers = await CenterService.fetchMarkers(newPosition);
      if (!mounted) return;

      setState(() {
        _currentPosition = newPosition;
        _markers = fetchedMarkers;
        _loading = false;
        _errorMessage = '';
      });

      if (_mapController != null && _markers.isNotEmpty) {
        final bounds = _createBoundsFromMarkers(_markers);
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 75),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _loading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }

    return await Geolocator.getCurrentPosition();
  }

  LatLngBounds _createBoundsFromMarkers(Set<Marker> markers) {
    final latitudes = markers.map((m) => m.position.latitude);
    final longitudes = markers.map((m) => m.position.longitude);

    final southwest = LatLng(
      latitudes.reduce((a, b) => a < b ? a : b),
      longitudes.reduce((a, b) => a < b ? a : b),
    );
    final northeast = LatLng(
      latitudes.reduce((a, b) => a > b ? a : b),
      longitudes.reduce((a, b) => a > b ? a : b),
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        if (_uploading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(
              color: Colors.grey,
              backgroundColor: Colors.black12,
            ),
          ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 14,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_markers.isNotEmpty) {
                final bounds = _createBoundsFromMarkers(_markers);
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 75),
                );
              }
            },
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 32, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: CustomButtonStyles.uploadButtonStyle(),
              onPressed: _onRecyclePressed,
              child: const Text("I am recycling documents"),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onRecyclePressed() async {
    if (_currentPosition == null || _markers.isEmpty || _uploading) return;

    final userLat = _currentPosition!.latitude;
    final userLng = _currentPosition!.longitude;

    double? nearestDistance;
    Marker? nearestCenterMarker;

    for (final marker in _markers) {
      final centerLat = marker.position.latitude;
      final centerLng = marker.position.longitude;
      final distance = Geolocator.distanceBetween(
        userLat,
        userLng,
        centerLat,
        centerLng,
      );

      if (nearestDistance == null || distance < nearestDistance) {
        nearestDistance = distance;
        nearestCenterMarker = marker;
      }
    }

    if (nearestDistance == null || nearestDistance > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must be within 100m of a recycling center to log a book.\n'
            'Nearest: ${nearestCenterMarker?.infoWindow.title ?? "Unknown"} '
            '(${nearestDistance!.toStringAsFixed(1)}m away)',
          ),
        ),
      );
      return;
    }

    final countController = TextEditingController();
    final pagesController = TextEditingController();
    final imagePicker = ImagePicker();
    List<XFile> images = [];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Recycle Confirmation'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextField(
                    controller: countController,
                    hintText: 'No. of documents (10 max.)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null) return 'Only whole numbers allowed';
                      if (parsed <= 0) return 'Must be greater than 0';
                      if (parsed > 10) return 'Maximum is 10';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  MyTextField(
                    controller: pagesController,
                    hintText: 'Total number of pages',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null) return 'Only whole numbers allowed';
                      if (parsed <= 0) return 'Must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: images
                        .map((img) => Image.file(File(img.path), height: 60))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: CustomButtonStyles.uploadButtonStyle(),
                    onPressed: () async {
                      final pickedList = await imagePicker.pickMultiImage();
                      if (!context.mounted) return;

                      if (pickedList.isNotEmpty) {
                        final total = images.length + pickedList.length;
                        if (total > 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You can upload a maximum of 10 images only.\nYou already have ${images.length}.',
                              ),
                            ),
                          );
                        } else {
                          setState(() => images.addAll(pickedList));
                        }
                      }
                    },
                    icon: const Icon(Icons.add_a_photo, color: Colors.black),
                    label: const Text('Add document cover photos'),
                  ),
                ],
              );
            },
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: CustomButtonStyles.uploadButtonStyle(),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: CustomButtonStyles.confirmButtonStyle(),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final count = int.tryParse(countController.text);
    final pages = int.tryParse(pagesController.text);

    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of documents.'),
        ),
      );
      return;
    }

    if (pages == null || pages <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid total number of pages.'),
        ),
      );
      return;
    }

    if (count > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can recycle a maximum of 10 documents at once.'),
        ),
      );
      return;
    }

    if (images.length != count) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must upload exactly $count photo${count == 1 ? '' : 's'} to match the number of documents.',
          ),
        ),
      );
      return;
    }

    setState(() => _uploading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ You must be logged in to recycle.')),
      );
      return;
    }

    final imageUrls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    bool uploadFailed = false;

    try {
      for (int i = 0; i < images.length; i++) {
        final file = File(images[i].path);
        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Image ${i + 1} exceeds 5MB limit. Upload canceled.',
              ),
            ),
          );
          uploadFailed = true;
          break;
        }

        final ref = FirebaseStorage.instance.ref(
          'recycled_documents/${user.uid}/$count/${timestamp}_$i.jpg',
        );
        final uploadTask = ref.putFile(file);

        await uploadTask;
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }
    } catch (e) {
      uploadFailed = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Upload failed: $e')));
    }

    setState(() => _uploading = false);

    if (uploadFailed) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'documentsRecycled': FieldValue.increment(count)},
      );
    } catch (e) {
      debugPrint('⚠️ Failed to increment documentsRecycled: $e');
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'pagesRecycled': FieldValue.increment(pages)},
      );
    } catch (e) {
      debugPrint('⚠️ Failed to increment pagesRecycled: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Successfully logged your recycled documents!'),
        ),
      );
    }
  }
}
