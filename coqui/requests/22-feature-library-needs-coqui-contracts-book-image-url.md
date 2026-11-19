# feature_library needs coqui_contracts: the address of a book page's picture

## What I need

Something in `Services` (or on `CourseCatalog`) that turns a book page's `img` (`BookPage.image`, for example `img/la-lluvia-1.png`) into the address the picture is served from. For example `String bookImageUrl(String path)` on `CourseCatalog`, or a `contentUrl(String path)` that serves every content file (books, audio, story files).

Today nothing in `Services` carries a base for the content files, so a feature cannot show a book's picture. The old page wrote `"libros/" + page.img + "?v=39"` itself (app.html:305 and 337, 358): the folder is relative to the old site, and the `?v=39` tag keeps a phone from showing an old copy.

## Why

Order 22: "a book page's image is a file path served by the old site: show it through an image widget given the URL base that `Services` or the shell provides; if nothing in `Services` carries a base for content files, file a request and take a `String Function(String path)` resolver in your module's constructor meanwhile".

## What I am using meanwhile

`LibraryModule({String Function(String path) imageUrl = defaultBookImageUrl, ImageProvider Function(String url) imageProvider = networkBookImage})`. The default resolver is the old site's relative path with its tag, `libros/<path>?v=39`. The shell can pass the real resolver when it builds the module; if the contract grows the member, the module reads it from `Services` and the constructor parameter goes.

`imageProvider` is only there so that tests and the dev entry (which have no network) can give the pictures another way.

## Order and branch

Order 22, branch `lane/feature_library/22`.
