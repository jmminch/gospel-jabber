/* Based largely on
 * https://developers.google.com/web/fundamentals/codelabs/offline */

/* Try fetching from the network first.  If that succeeds, cache the
 * response.  If it fails, then get the data from the cache. */
self.addEventListener('fetch', function(event) {
  event.respondWith(
    fetch(event.request).then(function(response) {

      /* Only want to cache data coming from this domain. */
      if(parseUri(response.url).host === location.hostname) {
        var clone = response.clone();
        console.log("Caching data for ", event.request.url);
        caches.open('jabber').then(function(cache) {
          cache.put(event.request, clone); });
      }

      return response;
    })
    .catch(function(e) {
      console.log("Using cache for ", event.request.url);
      return caches.match(event.request);
    })
  );
});

// parseUri 1.2.2
// (c) Steven Levithan <stevenlevithan.com>
// MIT License

function parseUri (str) {
	var	o   = parseUri.options,
		m   = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
		uri = {},
		i   = 14;

	while (i--) uri[o.key[i]] = m[i] || "";

	uri[o.q.name] = {};
	uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
		if ($1) uri[o.q.name][$1] = $2;
	});

	return uri;
};

parseUri.options = {
	strictMode: false,
	key: ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],
	q:   {
		name:   "queryKey",
		parser: /(?:^|&)([^&=]*)=?([^&]*)/g
	},
	parser: {
		strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
		loose:  /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
	}
};
