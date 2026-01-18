'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "9961b97286a2858e5fce7e0072ecbf1a",
"assets/AssetManifest.bin.json": "a65877337d3d7ff27025da748018f6cd",
"assets/assets/icons/admin.svg": "33376c73e450382e0a252985f651447b",
"assets/assets/icons/bathroom.svg": "7306b95639fdd6e35d79cb6f57bcfff8",
"assets/assets/icons/children.svg": "389b1eb4232fa378222d93a397197e1f",
"assets/assets/icons/default.svg": "ff2a9df38467da4548da6fa521c270b4",
"assets/assets/icons/grocery.svg": "e42e8502504f8c4bbbe6360d9d7461a5",
"assets/assets/icons/kitchen.svg": "a15834da15dad1a1ac4b055ed061f5bc",
"assets/assets/icons/laundry.svg": "dbb448734286449072ceb914099ae104",
"assets/assets/icons/living.svg": "3303a1531955a9d4f7d41f56dad6deeb",
"assets/assets/icons/maintenance.svg": "62b2a0f41b7fa95b9e8b138816c993c3",
"assets/assets/icons/outdoor.svg": "efbb77b5049401d8b570bc485e70742f",
"assets/assets/icons/pet.svg": "0a086b38175b002cbcec68a72059935d",
"assets/assets/icons/trophy.svg": "c284f87d8ee8cf63e9eb344a469b4af2",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "fd48591da362b8e47018f0efedc85884",
"assets/NOTICES": "e6569e08f4918440364939163ceab16d",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"delete-account.html": "100992f7bec540c0ceeaeac1f0c71457",
"favicon.png": "436fa49d43927a69eb8fe3405bf1f2c8",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "8b713ad948dd1aa0f92e36385043af43",
"icons/Icon-192.png": "ea7547a258829e66ab6d2d07ae6f39f0",
"icons/Icon-512.png": "2abfa6df364290a168c2761d41ceb9ce",
"icons/Icon-maskable-192.png": "ea7547a258829e66ab6d2d07ae6f39f0",
"icons/Icon-maskable-512.png": "2abfa6df364290a168c2761d41ceb9ce",
"icons/icon.svg": "8da3896a2e243935b3e944486d0e2852",
"index.html": "9a560b7b2a97c55f0959496f3c6a6100",
"/": "9a560b7b2a97c55f0959496f3c6a6100",
"main.dart.js": "767dba861bf3a7842f3405eeebecd6f6",
"manifest.json": "aaff4d5ebedd4a6a995fe00030b00858",
"privacy": "c43857e40a220529ffa388e29c517d72",
"privacy.html": "4d7a1b8c7e683d0bcae357a9f6e62b5e",
"splash/img/dark-1x.png": "cb636d98f442af9db27da7362c68710a",
"splash/img/dark-2x.png": "b62a2066848586b945c3df97bcb63d78",
"splash/img/dark-3x.png": "575d507d1598c346f333e4cf682f4500",
"splash/img/dark-4x.png": "f06efbd4bc78fd3af87caf095aa857d9",
"splash/img/light-1x.png": "cb636d98f442af9db27da7362c68710a",
"splash/img/light-2x.png": "b62a2066848586b945c3df97bcb63d78",
"splash/img/light-3x.png": "575d507d1598c346f333e4cf682f4500",
"splash/img/light-4x.png": "f06efbd4bc78fd3af87caf095aa857d9",
"vercel.json": "76f49845ab8b66875c4e4c09570c6c94",
"version.json": "42a2cc413fd66ac98934c991b3fdb95c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
