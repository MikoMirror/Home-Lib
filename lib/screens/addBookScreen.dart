import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage; // For mobile/desktop
import 'package:firebase_storage/firebase_storage.dart';
import '/services/FirestoreService.dart';
import '/models/book.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../widgets/CustomAppBar.dart';

class AddBookScreen extends StatefulWidget {
  final String collectionId;
  final String googleBooksApiKey;
  final Book? initialBook;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const AddBookScreen({
    required this.collectionId,
    required this.googleBooksApiKey,
    this.initialBook,
    required this.isDarkMode,
    required this.onThemeToggle,
    Key? key,
  }) : super(key: key);

  @override
  _AddBookScreenState createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _publishedDateController = TextEditingController();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoriesController = TextEditingController();
  final TextEditingController _pageCountController = TextEditingController();

  Timestamp? _selectedDate;
  File? _selectedImage;
  String? _imageUrl;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _initializeTextControllers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _descriptionController.dispose();
    _categoriesController.dispose();
    _pageCountController.dispose();
    _publishedDateController.dispose();
    super.dispose();
  }

  void _initializeTextControllers() {
    final initialBook = widget.initialBook;

    _titleController.text = initialBook?.title ?? '';
    _authorController.text = initialBook?.author ?? '';
    _isbnController.text = initialBook?.isbn ?? '';
    _descriptionController.text = initialBook?.description ?? '';
    _categoriesController.text = initialBook?.categories ?? '';
    _pageCountController.text = initialBook?.pageCount.toString() ?? '';

    _selectedDate = initialBook?.publishedDate;
    _publishedDateController.text = initialBook?.publishedDate != null
        ? DateFormat('yyyy-MM-dd')
            .format(initialBook!.publishedDate!.toDate())
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate?.toDate() ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate?.toDate()) {
      setState(() {
        _selectedDate = Timestamp.fromDate(picked);
        _publishedDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    Uint8List imageBytes = await pickedFile.readAsBytes(); 

    setState(() {
      _selectedImage = File(pickedFile.path); 
      _imageBytes = imageBytes; 
    });
  }
}

   Future<String?> _uploadImageToStorage(Uint8List imageBytes) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      if (kIsWeb) {
        // Web Upload Logic:
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('book_covers/$fileName.jpg');
        final metadata = firebase_storage.SettableMetadata(
            contentType: 'image/jpeg');
        firebase_storage.UploadTask uploadTask =
            storageRef.putData(imageBytes, metadata);
        firebase_storage.TaskSnapshot storageTaskSnapshot =
            await uploadTask.whenComplete(() {});
        return await storageTaskSnapshot.ref.getDownloadURL();
      } else {
        // Mobile/Desktop Upload Logic:
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('book_covers/$fileName.jpg');
        UploadTask uploadTask = storageRef.putFile(File(_selectedImage!.path));
        TaskSnapshot storageTaskSnapshot =
            await uploadTask.whenComplete(() {});
        return await storageTaskSnapshot.ref.getDownloadURL();
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    if (_selectedImage != null) {
      _imageUrl = await _uploadImageToStorage(_imageBytes!); 
    }
    Book newBook = Book(
      title: _titleController.text,
      author: _authorController.text,
      isbn: _isbnController.text,
      description: _descriptionController.text,
      categories: _categoriesController.text,
      pageCount: int.tryParse(_pageCountController.text) ?? 0,
      publishedDate: _selectedDate,
      imageUrl: _imageUrl, 
    );
    _firestoreService.addBook(widget.collectionId, newBook);
    _formKey.currentState!.reset();
    Navigator.of(context).pop();
  }
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomAppBar(
      title: 'Add Book',
      isDarkMode: widget.isDarkMode,
      onThemeToggle: widget.onThemeToggle,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a title' : null,
            ),
            TextFormField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: 'Author',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter an author' : null,
            ),
            TextFormField(
              controller: _isbnController,
              decoration: InputDecoration(
                labelText: 'ISBN',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              maxLines: 3,
            ),
            TextFormField(
              controller: _categoriesController,
              decoration: InputDecoration(
                labelText: 'Categories',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            TextFormField(
              controller: _pageCountController,
              decoration: InputDecoration(
                labelText: 'Page Count',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _publishedDateController,
              decoration: InputDecoration(
                labelText: 'Published Date',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).iconTheme.color),
              ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            _selectedImage != null
                ? Image.memory(_imageBytes!, height: 200.0, width: 200.0)
                : Container(
                    height: 200.0,
                    width: 200.0,
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    child: Icon(Icons.image, color: Theme.of(context).colorScheme.secondary),
                  ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Choose Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Add Book'),
            ),
          ],
        ),
      ),
    ),
  );
}
}