/// Why a picture cannot be drawn: the picture is not there (an old picture the index does not have, a name the sheet does
/// not have), the sheet does not say which of its pictures a reference is, or the size asked is not one the picture can
/// be.
class PictureError implements Exception {
  PictureError(this.message);

  final String message;

  @override
  String toString() => message;
}
