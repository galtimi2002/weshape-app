// The map behind the home screen: MapLibre GL JS with the OpenFreeMap
// "positron" base map, our solar layer on top of the land, and a pin.
//
// Flutter talks to it through window.WeShapeMap (lib/features/home/map/
// map_bridge_web.dart). Everything the app asks for before the map has loaded
// is remembered and applied once it has, so callers never wait on it.
(function () {
  'use strict';
  if (window.WeShapeMap) return;

  var MAPLIBRE_VERSION = '4.7.1';
  var STYLE_URL = 'https://tiles.openfreemap.org/styles/positron';
  var PAINT = ['background-color', 'fill-color', 'fill-outline-color', 'fill-opacity', 'line-color', 'text-color',
    'text-halo-color', 'fill-extrusion-color', 'circle-color', 'circle-stroke-color', 'raster-opacity'];

  // The dark look, set per kind of layer (an automatic inversion turned land black and sea grey).
  var DARK = {
    background: '#141B26',
    water: '#0A111C',
    waterLine: '#16253A',
    green: '#17202C',
    landuse: '#18212E',
    building: '#1C2635',
    road: '#2A3546',
    roadMinor: '#222C3B',
    rail: '#2E394B',
    border: '#4C5D78',
    text: '#8F9AAC',
    textStrong: '#B8C2D1',
    halo: '#121924'
  };

  function darkPaint(l, p) {
    var id = l.id;
    var isWater = /water|ocean|sea|lake|river/.test(id);
    if (p === 'raster-opacity') return 0.12;
    if (p === 'background-color') return DARK.background;
    if (p === 'text-color') return /country|state|city|capital/.test(id) ? DARK.textStrong : DARK.text;
    if (p === 'text-halo-color') return DARK.halo;
    if (p === 'fill-opacity') return undefined; // keep
    if (l.type === 'fill' || l.type === 'fill-extrusion') {
      if (isWater) return DARK.water;
      if (/building/.test(id)) return DARK.building;
      if (/park|wood|forest|grass|landcover|glacier|ice|sand|wetland/.test(id)) return DARK.green;
      return DARK.landuse;
    }
    if (l.type === 'line') {
      if (isWater) return DARK.waterLine;
      if (/boundary|admin/.test(id)) return DARK.border;
      if (/rail/.test(id)) return DARK.rail;
      if (/minor|service|path|track|street|link/.test(id)) return DARK.roadMinor;
      return DARK.road;
    }
    if (l.type === 'circle') return DARK.text;
    return undefined;
  }

  var map = null;
  var loaded = false;
  var container = null; // the element Flutter gave us
  var mapDiv = null;    // MapLibre draws here
  var shield = null;    // holds the blockers above the map
  var resizeObserver = null;
  var original = null; // positron's own paint colours, to restore the light look
  var labelFields = null; // positron's own label expressions
  var marker = null;
  var pending = [];
  function log() {
    var args = Array.prototype.slice.call(arguments);
    args.unshift('[WeShapeMap]');
    console.log.apply(console, args);
  }
  log('bridge script loaded');

  var state = { dark: false, language: 'en', overlay: null, interactive: true, onClick: null, onError: null };

  // ---------------------------------------------------------------- loading

  var libraryPromise = null;
  function loadLibrary() {
    if (window.maplibregl) return Promise.resolve();
    if (libraryPromise) return libraryPromise;
    libraryPromise = new Promise(function (resolve, reject) {
      var base = 'https://unpkg.com/maplibre-gl@' + MAPLIBRE_VERSION + '/dist/';
      var css = document.createElement('link');
      css.rel = 'stylesheet';
      css.href = base + 'maplibre-gl.css';
      document.head.appendChild(css);
      var script = document.createElement('script');
      script.src = base + 'maplibre-gl.js';
      script.onload = function () { resolve(); };
      script.onerror = function () { libraryPromise = null; reject(new Error('maplibre-gl did not load')); };
      document.head.appendChild(script);
    });
    return libraryPromise;
  }

  // Flutter creates the element before it is in the page; wait until it has a size.
  function whenSized(el) {
    return new Promise(function (resolve) {
      var started = Date.now(), reported = false;
      (function check() {
        if (el.isConnected && el.clientWidth > 0 && el.clientHeight > 0) { resolve(); return; }
        if (!reported && Date.now() - started > 2000) {
          reported = true;
          var chain = [], n = el;
          for (var i = 0; n && i < 8; i++) {
            var r = n.getBoundingClientRect ? n.getBoundingClientRect() : null;
            chain.push((n.tagName || n.nodeName) + (r ? ' ' + Math.round(r.width) + 'x' + Math.round(r.height) : '') +
              (n.style && n.style.cssText ? ' {' + n.style.cssText + '}' : ''));
            n = n.parentNode || n.host;
          }
          console.warn('[WeShapeMap] container not ready after 2s: connected=' + el.isConnected +
            ' size=' + el.clientWidth + 'x' + el.clientHeight + '\n' + chain.join('\n  < '));
        }
        requestAnimationFrame(check);
      })();
    });
  }

  function whenLoaded(fn) {
    if (loaded) fn(); else pending.push(fn);
  }

  // ---------------------------------------------------------------- dark look

  var probe = document.createElement('canvas').getContext('2d');
  function parseColor(s) {
    if (typeof s !== 'string') return null;
    probe.fillStyle = '#010203';
    probe.fillStyle = s;
    var v = probe.fillStyle;
    if (v === '#010203' && s.trim().toLowerCase() !== '#010203') return null;
    if (v.charAt(0) === '#') return [parseInt(v.slice(1, 3), 16), parseInt(v.slice(3, 5), 16), parseInt(v.slice(5, 7), 16), 1];
    var m = v.match(/[\d.]+/g).map(Number);
    return [m[0], m[1], m[2], m.length > 3 ? m[3] : 1];
  }

  // Lightness flipped, greys tinted towards the app's navy, colours softened.
  function toDark(s) {
    var c = parseColor(s);
    if (!c) return s;
    var r = c[0] / 255, g = c[1] / 255, b = c[2] / 255;
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, h = 0, sat = 0;
    if (mx !== mn) {
      var d = mx - mn;
      sat = l > .5 ? d / (2 - mx - mn) : d / (mx + mn);
      h = mx === r ? ((g - b) / d + (g < b ? 6 : 0)) : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
      h *= 60;
    }
    var nl = .075 + .78 * (1 - l);
    if (sat < .25) { h = 216; sat = Math.max(sat, .22); } else { sat *= .7; }
    return 'hsla(' + h.toFixed(0) + ',' + (sat * 100).toFixed(0) + '%,' + (nl * 100).toFixed(1) + '%,' + c[3] + ')';
  }

  function deep(v, f) {
    if (Array.isArray(v)) return v.map(function (x) { return deep(x, f); });
    return typeof v === 'string' ? f(v) : v;
  }

  function applyColors() {
    var layers = map.getStyle().layers;
    if (!original) {
      original = {};
      layers.forEach(function (l) {
        if (l.id.indexOf('ws-') === 0) return;
        PAINT.forEach(function (p) {
          // Only properties of the layer's own kind; asking a background layer
          // for its fill colour throws.
          var kind = p.indexOf('text-') === 0 ? 'symbol' : p.split('-')[0];
          if (kind !== l.type.split('-')[0]) return;
          try {
            var v = map.getPaintProperty(l.id, p);
            if (v !== undefined) original[l.id + '|' + p] = v;
          } catch (e) { /* not a property of this layer */ }
        });
      });
    }
    var byId = {};
    layers.forEach(function (l) { byId[l.id] = l; });
    Object.keys(original).forEach(function (key) {
      var parts = key.split('|'), v = original[key], l = byId[parts[0]];
      var value = v;
      if (state.dark && l) {
        var d = darkPaint(l, parts[1]);
        value = d === undefined ? v : d;
      }
      try { map.setPaintProperty(parts[0], parts[1], value); } catch (e) { /* layer gone */ }
    });
    if (map.getLayer('ws-border')) map.setPaintProperty('ws-border', 'line-color', state.dark ? '#9DB8E6' : '#1E3A6E');
    applyOverlayOpacity();
  }

  // Place names in the app's language where OpenStreetMap has them.
  function applyLanguage() {
    var layers = map.getStyle().layers;
    if (!labelFields) {
      labelFields = {};
      layers.forEach(function (l) {
        if (l.type !== 'symbol') return;
        try {
          var f = map.getLayoutProperty(l.id, 'text-field');
          if (f !== undefined) labelFields[l.id] = f;
        } catch (e) { /* no label */ }
      });
    }
    Object.keys(labelFields).forEach(function (id) {
      var field = ['coalesce', ['get', 'name:' + state.language], ['get', 'name:latin'], ['get', 'name']];
      try { map.setLayoutProperty(id, 'text-field', field); } catch (e) { /* layer gone */ }
    });
  }

  // ---------------------------------------------------------------- overlay

  function overlayOpacity() {
    var o = state.overlay;
    return o ? (state.dark ? o.opacity * .88 : o.opacity) : 0;
  }

  function applyOverlayOpacity() {
    if (map.getLayer('ws-overlay')) map.setPaintProperty('ws-overlay', 'raster-opacity', overlayOpacity());
  }

  function applyOverlay(fade) {
    var o = state.overlay;
    if (!o) return;
    var b = o.bounds; // west, south, east, north
    var coords = [[b[0], b[3]], [b[2], b[3]], [b[2], b[1]], [b[0], b[1]]];
    var source = map.getSource('ws-overlay');
    if (!source) {
      // The data goes over the land (parks, woods, built-up areas included,
      // so it has no holes) and under the water, roads, borders and names.
      var layers = map.getStyle().layers, beforeId;
      layers.some(function (l) {
        if (l.type !== 'background' && l.type !== 'fill') { beforeId = l.id; return true; }
        return false;
      });
      map.addSource('ws-overlay', { type: 'image', url: o.url, coordinates: coords });
      map.addLayer({
        id: 'ws-overlay', type: 'raster', source: 'ws-overlay',
        paint: { 'raster-opacity': overlayOpacity(), 'raster-fade-duration': 0, 'raster-resampling': 'linear', 'raster-opacity-transition': { duration: 300 } }
      }, beforeId);
      // Seas and lakes cover the data, as in the solar atlases.
      layers.forEach(function (l) {
        if (l.type === 'fill' && /water/.test(l.id)) {
          try { map.moveLayer(l.id, beforeId); } catch (e) { /* keep order */ }
        }
      });
      return;
    }
    if (!fade) { source.updateImage({ url: o.url, coordinates: coords }); return; }
    map.setPaintProperty('ws-overlay', 'raster-opacity', 0);
    setTimeout(function () {
      source.updateImage({ url: o.url, coordinates: coords });
      setTimeout(applyOverlayOpacity, 80);
    }, 280);
  }

  function addCountryBorders() {
    var sources = map.getStyle().sources;
    var vector = Object.keys(sources).filter(function (k) { return sources[k].type === 'vector'; })[0];
    if (!vector) return;
    try {
      map.addLayer({
        id: 'ws-border', type: 'line', source: vector, 'source-layer': 'boundary',
        filter: ['all', ['==', ['get', 'admin_level'], 2], ['!=', ['get', 'maritime'], 1]],
        paint: { 'line-color': '#1E3A6E', 'line-opacity': .5, 'line-width': ['interpolate', ['linear'], ['zoom'], 3, .6, 8, 1.6] }
      });
    } catch (e) { /* the tiles have no such layer */ }
  }

  // ---------------------------------------------------------------- API

  window.WeShapeMap = {
    /**
     * el: the element to draw in. opts: {dark, language, bounds:[w,s,e,n],
     * padding:[top,right,bottom,left], attribution}. onClick(lon, lat), onError(message).
     */
    mount: function (el, opts, onClick, onError) {
      state.onClick = onClick;
      state.onError = onError;
      state.dark = !!opts.dark;
      state.language = opts.language || 'en';
      container = el;
      log('mount', opts);
      // The map and, above it, invisible blockers where Flutter draws its
      // controls. A blocker is a sibling of the map, not inside it, so a click
      // on the search or the card bubbles up to Flutter but never reaches the map.
      el.style.position = 'relative';
      el.innerHTML = '';
      mapDiv = document.createElement('div');
      mapDiv.style.cssText = 'position:absolute;inset:0';
      shield = document.createElement('div');
      shield.style.cssText = 'position:absolute;inset:0;pointer-events:none;z-index:10';
      el.appendChild(mapDiv);
      el.appendChild(shield);
      Promise.all([loadLibrary(), whenSized(el)]).then(function () {
        if (container !== el) return; // unmounted meanwhile
        log('maplibre ready, container', el.clientWidth + 'x' + el.clientHeight);
        var p = opts.padding || [0, 0, 0, 0];
        map = new maplibregl.Map({
          container: mapDiv,
          style: STYLE_URL,
          bounds: opts.bounds,
          fitBoundsOptions: { padding: { top: p[0], right: p[1], bottom: p[2], left: p[3] } },
          attributionControl: false,
          dragRotate: false,
          pitchWithRotate: false,
          minZoom: 3,
          maxZoom: 17
        });
        map.touchZoomRotate.disableRotation();
        map.addControl(new maplibregl.AttributionControl({ compact: true, customAttribution: opts.attribution || '' }), 'bottom-left');
        map.on('error', function (e) {
          console.warn('[WeShapeMap] error', e && e.error);
          if (!loaded && state.onError) state.onError(String((e && e.error && e.error.message) || 'map error'));
        });
        window.__weShapeMapInstance = map; // for debugging in the browser console
        map.on('load', function () {
          loaded = true;
          log('style loaded', map.getStyle().layers.length + ' layers');
          addCountryBorders();
          applyOverlay(false);
          applyColors();
          applyLanguage();
          var queued = pending; pending = [];
          queued.forEach(function (fn) { fn(); });
        });
        map.on('click', function (e) {
          if (state.interactive && state.onClick) state.onClick(e.lngLat.lng, e.lngLat.lat);
        });
        map.getCanvas().style.cursor = 'crosshair';
        map.on('dragstart', function () { map.getCanvas().style.cursor = 'grabbing'; });
        map.on('dragend', function () { map.getCanvas().style.cursor = 'crosshair'; });
        resizeObserver = new ResizeObserver(function () { if (map) map.resize(); });
        resizeObserver.observe(el);
      }).catch(function (e) {
        console.warn('[WeShapeMap] mount failed', e);
        if (state.onError) state.onError(String(e && e.message || e));
      });
    },

    setDark: function (dark) {
      state.dark = !!dark;
      whenLoaded(applyColors);
    },

    setLanguage: function (code) {
      state.language = code;
      whenLoaded(applyLanguage);
    },

    /** bounds: [west, south, east, north]; the picture's rows are in Web Mercator. */
    setOverlay: function (url, bounds, opacity) {
      var had = !!state.overlay;
      state.overlay = { url: url, bounds: bounds, opacity: opacity };
      whenLoaded(function () { applyOverlay(had); });
    },

    fitBounds: function (bounds, top, right, bottom, left, animate) {
      whenLoaded(function () {
        map.fitBounds([[bounds[0], bounds[1]], [bounds[2], bounds[3]]],
          { padding: { top: top, right: right, bottom: bottom, left: left }, animate: !!animate, duration: 900 });
      });
    },

    flyTo: function (lon, lat, zoom, offsetX, offsetY) {
      whenLoaded(function () {
        map.flyTo({ center: [lon, lat], zoom: zoom, offset: [offsetX, offsetY], speed: 1.4, essential: true });
      });
    },

    setMarker: function (lon, lat, color) {
      whenLoaded(function () {
        if (!marker) {
          var el = document.createElement('div');
          el.style.cssText = 'width:44px;height:44px;display:grid;place-items:center;pointer-events:none';
          el.innerHTML = '<b style="position:absolute;width:44px;height:44px;border-radius:50%;border:2px solid;opacity:0;animation:wsping 2s ease-out infinite"></b>' +
            '<i style="width:14px;height:14px;border-radius:50%;background:#fff;border:3px solid;box-shadow:0 2px 8px rgba(0,0,0,.4)"></i>';
          if (!document.getElementById('ws-ping-style')) {
            var st = document.createElement('style');
            st.id = 'ws-ping-style';
            st.textContent = '@keyframes wsping{0%{transform:scale(.3);opacity:.9}100%{transform:scale(1.2);opacity:0}}';
            document.head.appendChild(st);
          }
          marker = new maplibregl.Marker({ element: el });
        }
        var node = marker.getElement();
        node.firstChild.style.borderColor = color;
        node.lastChild.style.borderColor = color;
        marker.setLngLat([lon, lat]).addTo(map);
      });
    },

    clearMarker: function () {
      whenLoaded(function () { if (marker) marker.remove(); });
    },

    zoomIn: function () { whenLoaded(function () { map.zoomIn(); }); },
    zoomOut: function () { whenLoaded(function () { map.zoomOut(); }); },

    /** Off while a Flutter menu or dialog covers the map, so clicks meant for it don't reach the map. */
    setInteractive: function (on) {
      state.interactive = !!on;
      if (container) container.style.pointerEvents = on ? 'auto' : 'none';
    },

    /** Lifts the attribution line above Flutter's bottom dock when they would overlap. */
    setAttributionBottom: function (px) {
      var corner = container && container.querySelector('.maplibregl-ctrl-bottom-left');
      if (corner) corner.style.bottom = px + 'px';
    },

    /** Rectangles [x, y, width, height, x, y, ...] in pixels where Flutter draws controls. */
    setBlockers: function (flat) {
      if (!shield) return;
      var n = Math.floor(flat.length / 4);
      while (shield.children.length > n) shield.removeChild(shield.lastChild);
      while (shield.children.length < n) {
        var b = document.createElement('div');
        b.style.cssText = 'position:absolute;pointer-events:auto';
        shield.appendChild(b);
      }
      for (var i = 0; i < n; i++) {
        var st = shield.children[i].style;
        st.left = flat[i * 4] + 'px';
        st.top = flat[i * 4 + 1] + 'px';
        st.width = flat[i * 4 + 2] + 'px';
        st.height = flat[i * 4 + 3] + 'px';
      }
    },

    destroy: function () {
      if (resizeObserver) resizeObserver.disconnect();
      if (map) map.remove();
      map = null; loaded = false; container = null; mapDiv = null; shield = null; original = null; labelFields = null; marker = null;
      resizeObserver = null; pending = []; state.overlay = null;
    }
  };
})();
