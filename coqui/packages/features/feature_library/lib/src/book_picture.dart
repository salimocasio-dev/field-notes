/// The picture of a page: one whole-number scale of device pixels to every picture pixel, nothing smoothed.
/// app.html:388-390 (`ajustaPic`), 112 (`.lbpic img`).
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// How many device pixels every picture pixel takes, and the size in logical pixels.
class BookPictureFit {
  const BookPictureFit(this.k, this.width, this.height);

  /// `k`: a whole number of device pixels to every art pixel; below 1 (a screen too small for the picture) a fraction, 0.2 at least.
  final double k;
  final double width;
  final double height;

  /// The whole-number scale is on whenever the picture fits at 1 or more.
  bool get whole => k >= 1;
}

// app.html: ajustaPic
/// The picture [nw] x [nh] in an area [aw] x [ah] (the padding already taken off) on a screen of [dpr].
BookPictureFit fitBookPicture({
  required double aw,
  required double ah,
  required int nw,
  required int nh,
  required double dpr,
}) {
  var k = (aw * dpr / nw < ah * dpr / nh ? aw * dpr / nw : ah * dpr / nh)
      .floorToDouble();
  if (k < 1) {
    final m = aw * dpr / nw < ah * dpr / nh ? aw * dpr / nw : ah * dpr / nh;
    k = m < 0.2 ? 0.2 : m;
  }
  return BookPictureFit(k, nw * k / dpr, nh * k / dpr);
}

/// A page's picture. It shows nothing until it has loaded (`visibility:hidden`), then at [fitBookPicture]'s size,
/// with 8 px corners.
class BookPicture extends StatefulWidget {
  const BookPicture({
    super.key,
    required this.provider,
    required this.availableWidth,
    required this.availableHeight,
  });

  final ImageProvider provider;

  /// The room the picture has, the area's padding taken off.
  final double availableWidth;
  final double availableHeight;

  @override
  State<BookPicture> createState() => _BookPictureState();
}

class _BookPictureState extends State<BookPicture> {
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
  void didUpdateWidget(BookPicture old) {
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
    final image = _image;
    if (image == null) return const SizedBox.shrink();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final fit = fitBookPicture(
      aw: widget.availableWidth,
      ah: widget.availableHeight,
      nw: image.width,
      nh: image.height,
      dpr: dpr,
    );
    final pixels = _pixels;
    Widget picture;
    if (fit.whole && pixels != null) {
      // every picture pixel is `k` whole device pixels, on whole device pixels
      picture = SizedBox(
        width: fit.width,
        height: fit.height,
        child: PixelView(
          pixels: pixels,
          width: image.width,
          height: image.height,
        ),
      );
    } else {
      picture = RawImage(
        image: image,
        width: fit.width,
        height: fit.height,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      );
    }
    return PictureFrame(background: const Color(0x00000000), child: picture);
  }
}
