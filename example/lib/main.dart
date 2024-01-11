import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor_plus/data/settings.dart';
import 'package:image_editor_plus/image_editor_plus.dart';

void main() {
  runApp(
    const MaterialApp(
      home: ImageEditorExample(),
    ),
  );
}

class ImageEditorExample extends StatefulWidget {
  const ImageEditorExample({
    super.key,
  });

  @override
  createState() => _ImageEditorExampleState();
}

class _ImageEditorExampleState extends State<ImageEditorExample> {
  Uint8List? imageData;

  @override
  void initState() {
    super.initState();
    loadAsset("image.jpg");
  }

  void loadAsset(String name) async {
    var data = await rootBundle.load('assets/$name');
    setState(() => imageData = data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    ImageEditor.i18n({
      'Processing...': 'Procesando...',
      'Crop image': 'Recortar imagen',
      'No Filter': 'Original',
      'Edit image': 'Editar imagen',
      'Custom': 'Personalizado',
      'Background Layer': 'Capa de fondo',
      'Add filters': 'Agregar filtros',
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text("ImageEditor Example"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageData != null) Expanded(child: Image.memory(imageData!)),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text("Single image editor"),
            onPressed: () async {
              var editedImage = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageEditor(
                    image: imageData,
                    config: const Settings(
                        // backgroundColor: Colors.white,
                        // primaryColor: Colors.deepOrange,
                        // secondaryColor: Colors.grey,
                        // textColor: Colors.black87,
                        // iconBack: Icons.arrow_back_ios_new,
                        // iconSave: Icons.save_alt_rounded,
                        // titleStyle: TextStyle(
                        //   fontWeight: FontWeight.w500,
                        //   fontSize: 19,
                        //   color: Colors.black87,
                        // ),
                        ),
                  ),
                ),
              );

              // replace with edited image
              if (editedImage != null) {
                imageData = editedImage;
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }
}
