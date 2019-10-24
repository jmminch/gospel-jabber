/* Based largely on
 * https://developers.google.com/web/fundamentals/codelabs/offline */

/* Try fetching from the network first.  If that succeeds, cache the
 * response.  If it fails, then get the data from the cache. */
self.addEventListener('fetch', function(event) {
  event.respondWith(
    fetch(event.request).then(function(response) {
      var clone = response.clone();
      console.log("Caching data for ", event.request.url);
      caches.open('jabber').then(function(cache) {
        cache.put(event.request, clone); });
      return response;
    })
    .catch(function(e) {
      console.log("Using cache for ", event.request.url);
      return caches.match(event.request);
    })
  );
});
