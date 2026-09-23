// Viewer-request rewrite: turn a directory-style path into the index.html key
// that actually exists in S3.
//
// An S3 REST origin (this module uses one, via OAI) serves object keys and
// nothing else -- it has no directory-index behaviour, and CloudFront's
// default_root_object applies only to "/". Without this, "/concepts/overview"
// asks S3 for a key that does not exist and the request falls through to the
// distribution's error handling.
//
//   /                      -> /index.html (same key default_root_object picks)
//   /concepts/overview     -> /concepts/overview/index.html
//   /concepts/overview/    -> /concepts/overview/index.html
//   /assets/main.9f2c.css  -> untouched (last segment has an extension)
//
// The extension test is deliberately "a dot in the LAST path segment", not "a
// dot anywhere in the URI": a path such as /v1.2/getting-started has a dot in
// an earlier segment and is still a page that needs index.html appended.
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.charAt(uri.length - 1) === '/') {
        request.uri = uri + 'index.html';
        return request;
    }

    var lastSegment = uri.substring(uri.lastIndexOf('/') + 1);
    if (lastSegment.indexOf('.') === -1) {
        request.uri = uri + '/index.html';
    }

    return request;
}
