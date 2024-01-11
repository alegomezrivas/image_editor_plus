library image_editor_plus;

import 'dart:async';
import 'dart:math' as math;
import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/presets.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor_plus/data/settings.dart';
import 'package:image_editor_plus/data/constants.dart';
import 'package:image_editor_plus/data/image_item.dart';
import 'package:image_editor_plus/data/layer.dart';
import 'package:image_editor_plus/layers/background_layer.dart';
import 'package:image_editor_plus/layers/image_layer.dart';
import 'package:image_editor_plus/loading_screen.dart';
import 'package:image_editor_plus/modules/layers_overlay.dart';
import 'package:image_editor_plus/options.dart' as o;
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

late Size viewportSize;
double viewportRatio = 1;

List<Layer> layers = [], undoLayers = [], removedLayers = [];
Map<String, String> _translations = {};

String i18n(String sourceString) =>
    _translations[sourceString.toLowerCase()] ?? sourceString;

class ImageEditor extends StatelessWidget {
  final dynamic image;
  final String? savePath;
  final Settings config;

  final o.ImagePickerOption? imagePickerOption;
  final o.CropOption? cropOption;
  final o.BlurOption? blurOption;
  final o.BrushOption? brushOption;
  final o.EmojiOption? emojiOption;
  final o.FiltersOption? filtersOption;
  final o.FlipOption? flipOption;
  final o.RotateOption? rotateOption;
  final o.TextOption? textOption;

  const ImageEditor({
    super.key,
    this.image,
    this.savePath,
    Color? appBarColor,
    this.imagePickerOption,
    this.config = const Settings(),
    this.cropOption = const o.CropOption(),
    this.blurOption = const o.BlurOption(),
    this.brushOption = const o.BrushOption(),
    this.emojiOption = const o.EmojiOption(),
    this.filtersOption = const o.FiltersOption(),
    this.flipOption = const o.FlipOption(),
    this.rotateOption = const o.RotateOption(),
    this.textOption = const o.TextOption(),
  });

  @override
  Widget build(BuildContext context) {
    if (image == null &&
        imagePickerOption?.captureFromCamera != true &&
        imagePickerOption?.pickFromGallery != true) {
      throw Exception(
          'No image to work with, provide an image or allow the image picker.');
    }

    return SingleImageEditor(
      image: image,
      config: config,
      savePath: savePath,
      imagePickerOption: imagePickerOption,
      cropOption: cropOption,
      blurOption: blurOption,
      brushOption: brushOption,
      emojiOption: emojiOption,
      filtersOption: filtersOption,
      flipOption: flipOption,
      rotateOption: rotateOption,
      textOption: textOption,
    );
  }

  static i18n(Map<String, String> translations) {
    translations.forEach((key, value) {
      _translations[key.toLowerCase()] = value;
    });
  }

  /// Set custom theme properties default is dark theme with white text
  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(background: Colors.black),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black87,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarTextStyle: TextStyle(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
  );

  /// Set custom theme properties default is light theme with black text
  static ThemeData themeLight = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.dark(
      background: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white70,
      iconTheme: IconThemeData(color: Colors.black),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      toolbarTextStyle: TextStyle(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
  );
}

/// Image editor with all option available
class SingleImageEditor extends StatefulWidget {
  final dynamic image;
  final String? savePath;
  final Settings config;

  final o.ImagePickerOption? imagePickerOption;
  final o.CropOption? cropOption;
  final o.BlurOption? blurOption;
  final o.BrushOption? brushOption;
  final o.EmojiOption? emojiOption;
  final o.FiltersOption? filtersOption;
  final o.FlipOption? flipOption;
  final o.RotateOption? rotateOption;
  final o.TextOption? textOption;

  const SingleImageEditor({
    super.key,
    this.image,
    this.savePath,
    this.imagePickerOption,
    required this.config,
    this.cropOption = const o.CropOption(),
    this.blurOption = const o.BlurOption(),
    this.brushOption = const o.BrushOption(),
    this.emojiOption = const o.EmojiOption(),
    this.filtersOption = const o.FiltersOption(),
    this.flipOption = const o.FlipOption(),
    this.rotateOption = const o.RotateOption(),
    this.textOption = const o.TextOption(),
  });

  @override
  createState() => _SingleImageEditorState();
}

class _SingleImageEditorState extends State<SingleImageEditor> {
  ImageItem currentImage = ImageItem();

  ScreenshotController screenshotController = ScreenshotController();

  @override
  void dispose() {
    layers.clear();
    undoLayers.clear();
    removedLayers.clear();
    super.dispose();
  }

  List<Widget> get filterActions {
    return [
      SizedBox(
        width: MediaQuery.of(context).size.width * .4,
        child: SingleChildScrollView(
          reverse: true,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon: Icon(
                  widget.config.iconUndo,
                  color: layers.length > 1 || removedLayers.isNotEmpty
                      ? widget.config.primaryColor
                      : widget.config.secondaryColor,
                ),
                onPressed: () {
                  if (removedLayers.isNotEmpty) {
                    layers.add(removedLayers.removeLast());
                    setState(() {});
                    return;
                  }

                  if (layers.length <= 1) return; // do not remove image layer

                  undoLayers.add(layers.removeLast());

                  setState(() {});
                },
              ),
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon: Icon(
                  widget.config.iconRedo,
                  color: undoLayers.isNotEmpty
                      ? widget.config.primaryColor
                      : widget.config.secondaryColor,
                ),
                onPressed: () {
                  if (undoLayers.isEmpty) return;

                  layers.add(undoLayers.removeLast());

                  setState(() {});
                },
              ),
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon: Icon(
                  widget.config.iconSave,
                  color: widget.config.primaryColor,
                ),
                onPressed: () async {
                  resetTransformation();
                  setState(() {});

                  loadingScreen.show(config: widget.config);

                  var binaryIntList = await screenshotController.capture(
                      pixelRatio: pixelRatio);

                  loadingScreen.hide();

                  if (mounted) Navigator.pop(context, binaryIntList);
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.image != null) {
      loadImage(widget.image!);
    }
  }

  double flipValue = 0;
  int rotateValue = 0;

  double x = 0;
  double y = 0;
  double z = 0;

  double lastScaleFactor = 1, scaleFactor = 1;
  double widthRatio = 1, heightRatio = 1, pixelRatio = 1;

  resetTransformation() {
    scaleFactor = 1;
    x = 0;
    y = 0;
    setState(() {});
  }

  /// obtain image Uint8List by merging layers
  Future<Uint8List?> getMergedImage() async {
    if (layers.length == 1 && layers.first is BackgroundLayerData) {
      return (layers.first as BackgroundLayerData).file.image;
    } else if (layers.length == 1 && layers.first is ImageLayerData) {
      return (layers.first as ImageLayerData).image.image;
    }

    return screenshotController.capture(pixelRatio: pixelRatio);
  }

  void showImageWithZoomOverlay(BuildContext context, Widget widget) {
    showDialog(
      context: context,
      builder: (context) => Material(
        color: Colors.white,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              ZoomOverlay(
                modalBarrierColor: Colors.black12, // Optional
                minScale: 0.5, // Optional
                maxScale: 5.0, // Optional
                animationCurve: Curves.fastOutSlowIn,
                animationDuration: const Duration(milliseconds: 300),
                twoTouchOnly: true,
                child: widget,
              ),
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  icon: const Icon(Icons.close, color: AppColors.textColor),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.white10,
    );
  }

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;
    // pixelRatio = MediaQuery.of(context).devicePixelRatio;

    var layersStack = Stack(
      alignment: Alignment.center,
      children: layers.map((layerItem) {
        // Background layer
        if (layerItem is BackgroundLayerData) {
          return BackgroundLayer(
            layerData: layerItem,
            onUpdate: () {
              setState(() {});
            },
          );
        }

        // Image layer
        if (layerItem is ImageLayerData) {
          return ImageLayer(
            layerData: layerItem,
            onUpdate: () {
              setState(() {});
            },
          );
        }

        // Blank layer
        return Container();
      }).toList(),
    );

    widthRatio = currentImage.width / viewportSize.width;
    heightRatio = currentImage.height / viewportSize.height;
    pixelRatio = math.max(heightRatio, widthRatio);

    return Theme(
      data: ImageEditor.themeLight,
      child: Scaffold(
        key: scaffoldGlobalKey,
        appBar: AppBar(
          backgroundColor: widget.config.backgroundColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              widget.config.iconBack,
              color: widget.config.textColor,
            ),
          ),
          title: Text(
            i18n('Edit image'),
            style: widget.config.titleStyle,
          ),
          actions: filterActions,
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 44),
          child: Stack(
            children: [
              GestureDetector(
                // onTap: () => showImageWithZoomOverlay(context, layersStack),
                onScaleStart: (details) {
                  lastScaleFactor = scaleFactor;
                },
                onScaleUpdate: (details) {
                  // scale
                  if (details.pointerCount == 2) {
                    // don't update the UI if the scale didn't change
                    if (details.scale == 1.0) {
                      return;
                    }
                    setState(() {
                      scaleFactor =
                          (lastScaleFactor * details.scale).clamp(0.5, 5.0);
                      scaleFactor = scaleFactor * lastScaleFactor;
                    });
                  }
                },
                onScaleEnd: (details) {
                  scaleFactor = 1;
                  x = 0;
                  y = 0;
                  setState(() {});
                },
                child: Center(
                  child: SizedBox(
                    height: currentImage.height / pixelRatio,
                    width: currentImage.width / pixelRatio,
                    child: Screenshot(
                      controller: screenshotController,
                      child: RotatedBox(
                        quarterTurns: rotateValue,
                        child: Transform(
                          transform: Matrix4(
                            1,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                            x,
                            y,
                            0,
                            1 / scaleFactor,
                          )..rotateY(flipValue),
                          alignment: FractionalOffset.center,
                          child: layersStack,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (layers.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  child: Container(
                    height: 48,
                    width: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: IconButton(
                      iconSize: 22,
                      color: Colors.white60,
                      padding: const EdgeInsets.all(0),
                      onPressed: () {
                        showModalBottomSheet(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(16),
                              topLeft: Radius.circular(16),
                            ),
                          ),
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ManageLayersOverlay(
                            layers: layers,
                            onUpdate: () => setState(() {}),
                          ),
                        );
                      },
                      icon: Icon(widget.config.iconLayers),
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          alignment: Alignment.bottomCenter,
          height: 100 + MediaQuery.of(context).padding.bottom,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.config.backgroundColor,
            shape: BoxShape.rectangle,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              if (widget.filtersOption != null)
                BottomButton(
                  icon: widget.config.iconFilter,
                  text: i18n('Filter'),
                  config: widget.config,
                  onTap: () async {
                    resetTransformation();

                    /// Use case: if you don't want to stack your filter, use
                    /// this logic. Along with code on line 888 and
                    /// remove line 889
                    // for (int i = 1; i < layers.length; i++) {
                    //   if (layers[i] is BackgroundLayerData) {
                    //     layers.removeAt(i);
                    //     break;
                    //   }
                    // }

                    loadingScreen.show(config: widget.config);
                    // Change the way you combine layers, to preserve image transformations,
                    // say rotation or flip.
                    // To revert the change, uncomment the line below
                    // And remove flip and rotate values
                    // var mergedImage = await getMergedImage();
                    var mergedImage = await screenshotController.capture(
                      pixelRatio: pixelRatio,
                    );
                    loadingScreen.hide();

                    if (!mounted) return;

                    Uint8List? filterAppliedImage = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageFilters(
                          image: mergedImage!,
                          options: widget.filtersOption,
                          config: widget.config,
                        ),
                      ),
                    );

                    if (filterAppliedImage == null) return;

                    // Added this, to preserve image transformations
                    flipValue = 0;
                    rotateValue = 0;
                    removedLayers.clear();
                    undoLayers.clear();

                    var layer = BackgroundLayerData(
                      file: ImageItem(filterAppliedImage),
                    );

                    /// Use case, if you don't want your filter to effect your
                    /// other elements such as emoji and text. Use insert
                    /// instead of add like in line 888
                    //layers.insert(1, layer);
                    layers.add(layer);

                    await layer.file.status;

                    setState(() {});
                  },
                ),
              if (widget.cropOption != null)
                BottomButton(
                  icon: widget.config.iconCrop,
                  text: i18n('Crop'),
                  config: widget.config,
                  onTap: () async {
                    resetTransformation();
                    loadingScreen.show(config: widget.config);
                    // Change the way you combine layers, to preserve image transformations,
                    // say rotation or flip
                    // To revert the change, uncomment the line below
                    // var mergedImage = await getMergedImage();
                    var mergedImage = await screenshotController.capture(
                      pixelRatio: pixelRatio,
                    );
                    loadingScreen.hide();

                    if (!mounted) return;

                    Uint8List? croppedImage = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageCropper(
                          image: mergedImage!,
                          config: widget.config,
                          availableRatios: widget.cropOption!.ratios,
                        ),
                      ),
                    );

                    if (croppedImage == null) return;

                    flipValue = 0;
                    rotateValue = 0;

                    await currentImage.load(croppedImage);
                    // Remove duplicate layers
                    if (layers.isNotEmpty && layers.length > 1) {
                      layers.removeLast();
                    }

                    setState(() {});
                  },
                ),
              if (widget.flipOption != null)
                BottomButton(
                  icon: widget.config.iconFlip,
                  text: i18n('Flip'),
                  config: widget.config,
                  onTap: () {
                    setState(() {
                      flipValue = flipValue == 0 ? math.pi : 0;
                    });
                  },
                ),
              if (widget.rotateOption != null)
                BottomButton(
                  icon: widget.config.iconRotateLeft,
                  text: i18n('Rotate left'),
                  config: widget.config,
                  onTap: () {
                    var t = currentImage.width;
                    currentImage.width = currentImage.height;
                    currentImage.height = t;

                    rotateValue--;
                    setState(() {});
                  },
                ),
              if (widget.rotateOption != null)
                BottomButton(
                  icon: widget.config.iconRotateRight,
                  text: i18n('Rotate right'),
                  config: widget.config,
                  onTap: () {
                    var t = currentImage.width;
                    currentImage.width = currentImage.height;
                    currentImage.height = t;

                    rotateValue++;
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  final picker = ImagePicker();

  Future<void> loadImage(dynamic imageFile) async {
    await currentImage.load(imageFile);

    layers.clear();

    layers.add(BackgroundLayerData(
      file: currentImage,
    ));

    setState(() {});
  }
}

/// Button used in bottomNavigationBar in ImageEditor
class BottomButton extends StatelessWidget {
  final VoidCallback? onTap, onLongPress;
  final Settings config;
  final IconData icon;
  final String text;

  const BottomButton({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.config,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: config.primaryColor,
              size: 32,
            ),
            // const SizedBox(height: 8),
            // Text(i18n(text)),
          ],
        ),
      ),
    );
  }
}

/// Crop given image with various aspect ratios
class ImageCropper extends StatefulWidget {
  final Uint8List image;
  final Settings config;
  final List<o.AspectRatio> availableRatios;

  const ImageCropper({
    super.key,
    required this.image,
    required this.config,
    this.availableRatios = const [
      o.AspectRatio(title: 'Custom'),
      o.AspectRatio(title: '1:1', ratio: 1),
      o.AspectRatio(title: '4:3', ratio: 4 / 3),
      o.AspectRatio(title: '5:4', ratio: 5 / 4),
      o.AspectRatio(title: '7:5', ratio: 7 / 5),
      o.AspectRatio(title: '16:9', ratio: 16 / 9),
    ],
  });

  @override
  createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  final GlobalKey<ExtendedImageEditorState> _controller =
      GlobalKey<ExtendedImageEditorState>();

  double? currentRatio;
  bool isLandscape = true;
  int rotateAngle = 0;

  double? get aspectRatio => currentRatio == null
      ? null
      : isLandscape
          ? currentRatio!
          : (1 / currentRatio!);

  @override
  void initState() {
    super.initState();
    if (widget.availableRatios.isNotEmpty) {
      currentRatio = widget.availableRatios.first.ratio;
    }
    _controller.currentState?.rotate(right: true);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ImageEditor.themeLight,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.config.backgroundColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              widget.config.iconBack,
              color: widget.config.textColor,
            ),
          ),
          title: Text(
            i18n('Crop image'),
            style: widget.config.titleStyle,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(
                widget.config.iconSave,
                color: widget.config.primaryColor,
              ),
              onPressed: () async {
                loadingScreen.show(config: widget.config);
                var state = _controller.currentState;

                if (state == null || state.getCropRect() == null) {
                  loadingScreen.hide();
                  Navigator.pop(context);
                }

                var data = await cropImageWithThread(
                  imageBytes: state!.rawImageData,
                  rect: state.getCropRect()!,
                );

                loadingScreen.hide();

                if (mounted) Navigator.pop(context, data);
              },
            ),
          ],
        ),
        body: Container(
          color: widget.config.backgroundColor,
          child: ExtendedImage.memory(
            widget.image,
            cacheRawData: true,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            extendedImageEditorKey: _controller,
            mode: ExtendedImageMode.editor,
            initEditorConfigHandler: (state) {
              return EditorConfig(
                cropAspectRatio: aspectRatio,
                cornerColor: widget.config.primaryColor,
              );
            },
          ),
        ),
        bottomNavigationBar: Container(
          alignment: Alignment.bottomCenter,
          height: 100 + MediaQuery.of(context).padding.bottom,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.config.backgroundColor,
            shape: BoxShape.rectangle,
          ),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (currentRatio != null && currentRatio != 1)
                    IconButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      icon: Icon(
                        widget.config.iconPortrait,
                        color: isLandscape
                            ? widget.config.secondaryColor
                            : widget.config.primaryColor,
                      ),
                      onPressed: () {
                        isLandscape = false;

                        setState(() {});
                      },
                    ),
                  if (currentRatio != null && currentRatio != 1)
                    IconButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      icon: Icon(
                        widget.config.iconLandscape,
                        color: isLandscape
                            ? widget.config.primaryColor
                            : widget.config.secondaryColor,
                      ),
                      onPressed: () {
                        isLandscape = true;

                        setState(() {});
                      },
                    ),
                  for (var ratio in widget.availableRatios)
                    TextButton(
                      onPressed: () {
                        currentRatio = ratio.ratio;

                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          i18n(ratio.title),
                          style: widget.config.normalStyle.copyWith(
                            color: currentRatio == ratio.ratio
                                ? widget.config.primaryColor
                                : widget.config.secondaryColor,
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> cropImageWithThread({
    required Uint8List imageBytes,
    required Rect rect,
  }) async {
    img.Command cropTask = img.Command();
    cropTask.decodeImage(imageBytes);

    cropTask.copyCrop(
      x: rect.topLeft.dx.ceil(),
      y: rect.topLeft.dy.ceil(),
      height: rect.height.ceil(),
      width: rect.width.ceil(),
    );

    img.Command encodeTask = img.Command();
    encodeTask.subCommand = cropTask;
    encodeTask.encodeJpg();

    return encodeTask.getBytesThread();
  }
}

/// Return filter applied Uint8List image
class ImageFilters extends StatefulWidget {
  final Uint8List image;
  final Settings config;

  /// apply each filter to given image in background and cache it to improve UX
  final bool useCache;
  final o.FiltersOption? options;

  const ImageFilters({
    super.key,
    required this.image,
    required this.config,
    this.useCache = true,
    this.options,
  });

  @override
  createState() => _ImageFiltersState();
}

class _ImageFiltersState extends State<ImageFilters> {
  late img.Image decodedImage;
  ColorFilterGenerator selectedFilter = PresetFilters.none;
  Uint8List resizedImage = Uint8List.fromList([]);
  double filterOpacity = 1;
  Uint8List? filterAppliedImage;
  ScreenshotController screenshotController = ScreenshotController();
  late List<ColorFilterGenerator> filters;

  @override
  void initState() {
    super.initState();
    filters = [
      PresetFilters.none,
      ...(widget.options?.filters ?? presetFiltersList.sublist(1))
    ];

    // decodedImage = img.decodeImage(widget.image)!;
    // resizedImage = img.copyResize(decodedImage, height: 64).getBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ImageEditor.themeLight,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.config.backgroundColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(widget.config.iconBack, color: widget.config.textColor),
          ),
          title: Text(
            i18n('Add filters'),
            style: widget.config.titleStyle,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(
                widget.config.iconSave,
                color: widget.config.primaryColor,
              ),
              onPressed: () async {
                loadingScreen.show(config: widget.config);
                var data = await screenshotController.capture();
                loadingScreen.hide();
                if (mounted) Navigator.pop(context, data);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Center(
            child: Screenshot(
              controller: screenshotController,
              child: Stack(
                children: [
                  Image.memory(
                    widget.image,
                    fit: BoxFit.cover,
                  ),
                  FilterAppliedImage(
                    key: Key(selectedFilter.name),
                    image: widget.image,
                    filter: selectedFilter,
                    fit: BoxFit.cover,
                    opacity: filterOpacity,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          alignment: Alignment.bottomCenter,
          height: 190 + MediaQuery.of(context).padding.bottom,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: widget.config.backgroundColor,
            shape: BoxShape.rectangle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 40,
                child: selectedFilter == PresetFilters.none
                    ? Container()
                    : selectedFilter.build(
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 1.0,
                            activeTrackColor: widget.config.primaryColor,
                            inactiveTrackColor: widget.config.primaryColor,
                            thumbColor: widget.config.primaryColor,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10.0,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: 1,
                            divisions: 100,
                            value: filterOpacity,
                            onChanged: (value) {
                              filterOpacity = value;
                              setState(() {});
                            },
                          ),
                        ),
                      ),
              ),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var filter in filters)
                      GestureDetector(
                        onTap: () {
                          selectedFilter = filter;
                          setState(() {});
                        },
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(48),
                                border: Border.all(
                                  color: selectedFilter == filter
                                      ? widget.config.primaryColor
                                      : widget.config.secondaryColor,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(48),
                                child: FilterAppliedImage(
                                  key: Key(filter.name),
                                  image: widget.image,
                                  filter: filter,
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),
                            Text(
                              i18n(filter.name),
                              style: widget.config.normalStyle,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterAppliedImage extends StatefulWidget {
  final Uint8List image;
  final ColorFilterGenerator filter;
  final BoxFit? fit;
  final Function(Uint8List)? onProcess;
  final double opacity;

  const FilterAppliedImage({
    super.key,
    required this.image,
    required this.filter,
    this.fit,
    this.onProcess,
    this.opacity = 1,
  });

  @override
  State<FilterAppliedImage> createState() => _FilterAppliedImageState();
}

class _FilterAppliedImageState extends State<FilterAppliedImage> {
  @override
  initState() {
    super.initState();

    // process filter in background
    if (widget.onProcess != null) {
      // no filter supplied
      if (widget.filter.filters.isEmpty) {
        widget.onProcess!(widget.image);
        return;
      }

      var filterTask = img.Command();
      filterTask.decodeImage(widget.image);

      var matrix = widget.filter.matrix;

      filterTask.filter((image) {
        for (final pixel in image) {
          pixel.r = matrix[0] * pixel.r +
              matrix[1] * pixel.g +
              matrix[2] * pixel.b +
              matrix[3] * pixel.a +
              matrix[4];

          pixel.g = matrix[5] * pixel.r +
              matrix[6] * pixel.g +
              matrix[7] * pixel.b +
              matrix[8] * pixel.a +
              matrix[9];

          pixel.b = matrix[10] * pixel.r +
              matrix[11] * pixel.g +
              matrix[12] * pixel.b +
              matrix[13] * pixel.a +
              matrix[14];

          pixel.a = matrix[15] * pixel.r +
              matrix[16] * pixel.g +
              matrix[17] * pixel.b +
              matrix[18] * pixel.a +
              matrix[19];
        }

        return image;
      });

      filterTask.getBytesThread().then((result) {
        if (widget.onProcess != null && result != null) {
          widget.onProcess!(result);
        }
      }).catchError((err, stack) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filter.filters.isEmpty) {
      return Image.memory(
        widget.image,
        fit: widget.fit,
      );
    }

    return Opacity(
      opacity: widget.opacity,
      child: widget.filter.build(
        Image.memory(
          widget.image,
          fit: widget.fit,
        ),
      ),
    );
  }
}
