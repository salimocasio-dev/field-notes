/// A story book's picture in Repaso's games (the moment he first heard a sentence): one whole-number scale of device
/// pixels to every picture pixel, nothing smoothed (page 11-pixel-engine, decision 3). A local copy of the way
/// Biblioteca shows a page (feature_library's BookPicture): a feature does not import another.
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Turns a book page's `img` (`img/<file>`) into the address of the file.
typedef BookImageUrl = String Function(String path);

/// Turns an address into the picture to load.
typedef BookImageProvider = ImageProvider Function(String url);

/// app.html:305 (`BV`): `libros/` + the path + `?v=39`, the old site's relative address.
String defaultBookImageUrl(String path) => 'libros/$path?v=39';

/// The picture at [url], over the network.
ImageProvider networkBookImage(String url) => NetworkImage(url);

/// The book pictures' size in picture pixels (every page of every book: 196 x 216).
const int bookPictureWidth = 196;
const int bookPictureHeight = 216;

/// The whole scale of device pixels to a picture pixel for a picture of [w] x [h] in [aw] x [ah] logical pixels on a
/// screen of [dpr]; 1 at least.
int bookScale({
  required double aw,
  required double ah,
  required double dpr,
  int w = bookPictureWidth,
  int h = bookPictureHeight,
}) {
  final k = (aw * dpr / w < ah * dpr / h ? aw * dpr / w : ah * dpr / h).floor();
  return k < 1 ? 1 : k;
}

/// A book picture at the whole scale [k] (device pixels to a picture pixel): [k] * 196 / ratio logical pixels wide.
/// Nothing shows until it has loaded; its room is kept, so nothing moves when it comes.
class BookImage extends StatefulWidget {
  const BookImage({super.key, required this.provider, required this.k});

  final ImageProvider provider;
  final int k;

  @override
  State<BookImage> createState() => _BookImageState();
}

class _BookImageState extends State<BookImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  Uint32List? _pixels;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(BookImage old) {
    super.didUpdateWidget(old);
    if (old.provider != widget.provider) {
      _forget();
      _image = null;
      _pixels = null;
      _resolve();
    }
  }

  @override
  void dispose() {
    _forget();
    super.dispose();
  }

  void _forget() {
    _token++;
    final l = _listener;
    if (l != null) _stream?.removeListener(l);
    _stream = null;
    _listener = null;
  }

  void _resolve() {
    final stream = widget.provider.resolve(ImageConfiguration.empty);
    final token = ++_token;
    final listener = ImageStreamListener(
      (info, sync) => unawaited(_got(info.image, token)),
      onError: (error, stack) {},
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  Future<void> _got(ui.Image image, int token) async {
    ByteData? bytes;
    try {
      bytes = await image.toByteData();
    } on Object {
      bytes = null;
    }
    if (!mounted || token != _token) return;
    setState(() {
      _image = image;
      _pixels = bytes == null
          ? null
          : Uint32List.view(
              bytes.buffer,
              bytes.offsetInBytes,
              image.width * image.height,
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = _image;
    final w = (image?.width ?? bookPictureWidth) * widget.k / dpr;
    final h = (image?.height ?? bookPictureHeight) * widget.k / dpr;
    final pixels = _pixels;
    return ExcludeSemantics(
      child: SizedBox(
        width: w,
        height: h,
        child: image == null
            ? null
            : pixels != null
            ? PixelView(
                pixels: pixels,
                width: image.width,
                height: image.height,
              )
            : RawImage(
                image: image,
                width: w,
                height: h,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
      ),
    );
  }
}
