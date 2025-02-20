import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AddMealsPage extends StatefulWidget {
  const AddMealsPage({super.key});

  @override
  _AddMealsPageState createState() => _AddMealsPageState();
}

class _AddMealsPageState extends State<AddMealsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  String? selectedCategoryId;

  bool isNuts = false;
  bool isHalal = false;
  bool isDairy = false;
  bool isSeafood = false;

  Uint8List? _imageBytes;
  String? _imageName;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> ingredients = [];
  List<Map<String, dynamic>> instructions = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('meal_category')
          .select('meal_category_id, category_name');
      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = image.name;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null || _imageName == null) {
      print('No image selected');
      return null;
    }

    try {
      // Generate a shorter, clean filename
      final String cleanedFileName =
          _imageName!.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
      final String timestamp =
          DateTime.now().millisecondsSinceEpoch.toString().substring(5);
      final fileName = '${timestamp}_$cleanedFileName';
      print('Attempting to upload image with filename: $fileName');

      // Upload the image
      await Supabase.instance.client.storage.from('meal-images').uploadBinary(
            fileName,
            _imageBytes!,
            fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      print('Image uploaded successfully');

      // Get the public URL
      final String publicUrl = Supabase.instance.client.storage
          .from('meal-images')
          .getPublicUrl(fileName);

      print('Generated URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Error during image upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  void _addIngredient() {
    setState(() {
      ingredients.add({
        'name': '',
        'quantity': '',
        'unit': '',
        'produce_id': null,
      });
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      ingredients.removeAt(index);
    });
  }

  void _addInstruction() {
    setState(() {
      instructions.add({
        'step_number': instructions.length + 1,
        'instruction': '',
      });
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      instructions.removeAt(index);
      // Update step numbers for remaining instructions
      for (int i = index; i < instructions.length; i++) {
        instructions[i]['step_number'] = i + 1;
      }
    });
  }

  Future<void> _handleAddMeal() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // 1. Upload image first
        final imageUrl = await _uploadImage();
        if (imageUrl == null && _imageBytes != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
          return;
        }

        // 2. Insert meal record
        final mealResponse = await Supabase.instance.client
            .from('meal')
            .insert({
              'name': nameController.text,
              'description': descriptionController.text,
              'image_url': imageUrl,
              'meal_category_id': selectedCategoryId,
              'is_nuts': isNuts,
              'is_halal': isHalal,
              'is_dairy': isDairy,
              'is_seafood': isSeafood,
            })
            .select()
            .single();

        final recipeId = mealResponse['recipe_id'];

        // 3. Insert ingredients
        if (ingredients.isNotEmpty) {
          await Supabase.instance.client.from('ingredients').insert(
                ingredients
                    .map((ingredient) => {
                          'recipe_id': recipeId,
                          'name': ingredient['name'],
                          'quantity': ingredient['quantity'],
                          'unit': ingredient['unit'],
                          'produce_id': ingredient['produce_id'],
                        })
                    .toList(),
              );
        }

        // 4. Insert instructions
        if (instructions.isNotEmpty) {
          await Supabase.instance.client.from('instructions').insert(
                instructions
                    .map((instruction) => {
                          'recipe_id': recipeId,
                          'step_number': instruction['step_number'],
                          'instruction': instruction['instruction'],
                        })
                    .toList(),
              );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal added successfully!')),
        );
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding meal: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    nameController.clear();
    descriptionController.clear();
    setState(() {
      selectedCategoryId = null;
      isNuts = false;
      isHalal = false;
      isDairy = false;
      isSeafood = false;
      _imageBytes = null;
      _imageName = null;
      ingredients.clear();
      instructions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Meal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Image Upload
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50),
                              Text('Click to add image'),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Basic Information
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Meal Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category['meal_category_id'].toString(),
                    child: Text(category['category_name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 20),

              // Dietary Preferences
              const Text(
                'Dietary Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                title: const Text('Contains Nuts'),
                value: isNuts,
                onChanged: (value) {
                  setState(() {
                    isNuts = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Halal'),
                value: isHalal,
                onChanged: (value) {
                  setState(() {
                    isHalal = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Contains Dairy'),
                value: isDairy,
                onChanged: (value) {
                  setState(() {
                    isDairy = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Contains Seafood'),
                value: isSeafood,
                onChanged: (value) {
                  setState(() {
                    isSeafood = value ?? false;
                  });
                },
              ),

              // Ingredients Section
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ingredients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Ingredient'),
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Ingredient Name',
                              ),
                              onChanged: (value) {
                                ingredients[index]['name'] = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                              ),
                              onChanged: (value) {
                                ingredients[index]['quantity'] = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                              ),
                              onChanged: (value) {
                                ingredients[index]['unit'] = value;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeIngredient(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Instructions Section
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Instructions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addInstruction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Step'),
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: instructions.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Step ${index + 1}',
                              ),
                              onChanged: (value) {
                                instructions[index]['instruction'] = value;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeInstruction(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleAddMeal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Save Meal',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
