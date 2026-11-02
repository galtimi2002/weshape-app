// The map behind the home screen: MapLibre GL JS with the OpenFreeMap
// "positron" base map, our resource layer (solar picture or wind tiles) on top
// of the land, and a pin.
//
// Flutter talks to it through window.WeShapeMap (lib/features/home/map/
// map_bridge_web.dart). Everything the app asks for before the map has loaded
// is remembered and applied once it has, so callers never wait on it.
(function () {
  'use strict';
  // Must match _bridgeVersion in map_bridge_web.dart. A newer copy replaces an older one
  // (after a hot restart the page still holds the previous script).
  var VERSION = 12;
  if (window.WeShapeMap && window.WeShapeMap.version === VERSION) return;
  if (window.WeShapeMap && window.WeShapeMap.destroy) {
    try { window.WeShapeMap.destroy(); } catch (e) { /* already gone */ }
  }

  var MAPLIBRE_VERSION = '4.7.1';
  var STYLE_URL = 'https://tiles.openfreemap.org/styles/positron';
  var PAINT = ['background-color', 'fill-color', 'fill-outline-color', 'fill-opacity', 'line-color', 'text-color',
    'text-halo-color', 'fill-extrusion-color', 'circle-color', 'circle-stroke-color', 'raster-opacity'];

  // The dark look, set per kind of layer (an automatic inversion turned land black and sea grey).
  var DARK = {
    background: '#141B26',
    water: '#122A42',
    waterLine: '#1D3D5E',
    green: '#17202C',
    landuse: '#18212E',
    building: '#1C2635',
    road: 'rgba(190,205,225,0.30)',
    roadMinor: 'rgba(190,205,225,0.16)',
    rail: 'rgba(190,205,225,0.22)',
    border: '#4C5D78',
    text: '#8F9AAC',
    textStrong: '#B8C2D1',
    halo: '#121924'
  };

  // In the light look only the water changes: positron's grey water read as a road.
  var LIGHT = {
    water: '#BCD5E8',
    waterLine: '#9FC3DE'
  };

  function isWaterLayer(id) {
    return /water|ocean|sea|lake|river|dam/.test(id);
  }

  function lightPaint(l, p) {
    if (!isWaterLayer(l.id)) return undefined;
    if (l.type === 'fill' && (p === 'fill-color' || p === 'fill-outline-color')) return LIGHT.water;
    if (l.type === 'line' && p === 'line-color') return LIGHT.waterLine;
    return undefined;
  }

  function darkPaint(l, p) {
    var id = l.id;
    var isWater = isWaterLayer(id);
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

  var state = { dark: false, language: 'en', overlay: null, overlayKey: null, overlayKind: null, overlayToken: 0,
    attribution: '', attributionBottom: 0, interactive: true, onClick: null, onError: null };
  var attributionControl = null;

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
      if (l) {
        var d = state.dark ? darkPaint(l, parts[1]) : lightPaint(l, parts[1]);
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
          // Only place names: road shields show a road number ("ref"), not a name,
          // and turning them into names left them empty.
          if (f !== undefined && /name/.test(JSON.stringify(f))) labelFields[l.id] = f;
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
    return o ? (state.dark && o.kind !== 'rivers' ? o.opacity * .88 : o.opacity) : 0;
  }

  /** The paint property that fades our layer: raster for pictures and tiles, line for rivers. */
  function opacityProperty() {
    return state.overlayKind === 'rivers' ? 'line-opacity' : 'raster-opacity';
  }

  /**
   * Rivers: the reaches follow a ~500 m grid, so from zoom 11 on they fade and the base
   * map's real river bed takes over; they stay clickable and keep their colour.
   */
  function opacityValue(value) {
    if (state.overlayKind !== 'rivers' || !value) return value;
    return ['interpolate', ['linear'], ['zoom'], 10, value, 13, value * 0.4];
  }

  function applyOverlayOpacity() {
    if (map.getLayer('ws-overlay')) map.setPaintProperty('ws-overlay', opacityProperty(), opacityValue(overlayOpacity()));
  }

  function setOverlayOpacity(value) {
    if (map.getLayer('ws-overlay')) map.setPaintProperty('ws-overlay', opacityProperty(), opacityValue(value));
  }

  /** The first layer above the land fills (roads, borders, names), not counting our own. */
  function aboveFillsId() {
    var id;
    map.getStyle().layers.some(function (l) {
      if (l.id !== 'ws-overlay' && l.type !== 'background' && l.type !== 'fill') { id = l.id; return true; }
      return false;
    });
    return id;
  }

  /** The first layer above the land, the water and the base map's own river lines. */
  function aboveWaterId() {
    var id;
    map.getStyle().layers.some(function (l) {
      if (l.id === 'ws-overlay' || l.type === 'background' || l.type === 'fill') return false;
      if (l.type === 'line' && isWaterLayer(l.id)) return false;
      id = l.id;
      return true;
    });
    return id;
  }

  /**
   * Solar: seas and lakes cover the data, as in the solar atlases.
   * Wind: the data covers them too, because the atlas has values along the coast.
   * Rivers: lakes and seas stay under the lines, which sit above the water.
   */
  function arrangeWater(waterOnTop) {
    var target = waterOnTop ? aboveFillsId() : 'ws-overlay';
    map.getStyle().layers.forEach(function (l) {
      if (l.type === 'fill' && /water/.test(l.id)) {
        try { map.moveLayer(l.id, target); } catch (e) { /* keep order */ }
      }
    });
  }

  /** A value on the layer's scale (log or linear) mapped onto its colours. */
  function riverColor(r) {
    var value = ['to-number', ['get', r.property], 0];
    var lo = r.min, hi = r.max, n = r.colors.length;
    var input = r.log ? ['ln', ['max', value, lo / 10]] : value;
    var a = r.log ? Math.log(lo) : lo, b = r.log ? Math.log(hi) : hi;
    var expr = ['interpolate', ['linear'], input];
    r.colors.forEach(function (c, i) { expr.push(a + (b - a) * i / (n - 1), c); });
    return expr;
  }

  /** Wider lines for bigger rivers, and all of them wider as the map zooms in. */
  function riverWidth(r) {
    function byFlow(thin, wide) {
      return ['interpolate', ['linear'], ['ln', ['max', ['to-number', ['get', r.widthProperty], 0.1], 0.1]],
        Math.log(0.1), thin, Math.log(5000), wide];
    }
    return ['interpolate', ['linear'], ['zoom'],
      0, byFlow(0.9, 2.6), 5, byFlow(1.3, 4.2), 8, byFlow(1.7, 6), 11, byFlow(2, 7), 15, byFlow(2.4, 8)];
  }

  function addOverlay(o, opacity) {
    var b = o.bounds; // west, south, east, north
    state.overlayKind = o.kind;
    if (o.kind === 'rivers') {
      map.addSource('ws-overlay', { type: 'vector', tiles: [o.url], bounds: b, minzoom: 0, maxzoom: o.maxZoom || 10 });
      arrangeWater(true);
      map.addLayer({
        id: 'ws-overlay', type: 'line', source: 'ws-overlay', 'source-layer': o.river.sourceLayer,
        layout: { 'line-cap': 'round', 'line-join': 'round' },
        paint: {
          'line-color': riverColor(o.river), 'line-width': riverWidth(o.river), 'line-opacity': opacityValue(opacity),
          'line-opacity-transition': { duration: 300 }, 'line-color-transition': { duration: 300 }
        }
      }, aboveWaterId());
      state.overlayKey = o.kind + '|' + o.url;
      state.overlayKind = o.kind;
      return;
    }
    var spec = o.kind === 'tiles'
      ? { type: 'raster', tiles: [o.url], tileSize: 256, bounds: b, minzoom: 0, maxzoom: o.maxZoom || 10 }
      : { type: 'image', url: o.url, coordinates: [[b[0], b[3]], [b[2], b[3]], [b[2], b[1]], [b[0], b[1]]] };
    map.addSource('ws-overlay', spec);
    // The data goes over the land (parks, woods, built-up areas included, so it
    // has no holes) and under the roads, borders and names.
    map.addLayer({
      id: 'ws-overlay', type: 'raster', source: 'ws-overlay',
      paint: {
        'raster-opacity': opacity, 'raster-fade-duration': o.kind === 'tiles' ? 200 : 0,
        'raster-resampling': 'linear', 'raster-opacity-transition': { duration: 300 }
      }
    }, aboveFillsId());
    arrangeWater(o.kind !== 'tiles');
    state.overlayKey = o.kind + '|' + o.url;
    state.overlayKind = o.kind;
  }

  function removeOverlay() {
    if (map.getLayer('ws-overlay')) map.removeLayer('ws-overlay');
    if (map.getSource('ws-overlay')) map.removeSource('ws-overlay');
  }

  function applyOverlay(fade) {
    var o = state.overlay;
    if (!o) return;
    var key = o.kind + '|' + o.url;
    var source = map.getSource('ws-overlay');
    if (!source) { addOverlay(o, overlayOpacity()); return; }
    if (key === state.overlayKey) {
      // Same river tiles, another layer: only the colours change.
      if (o.kind === 'rivers') map.setPaintProperty('ws-overlay', 'line-color', riverColor(o.river));
      applyOverlayOpacity();
      return;
    }
    var token = ++state.overlayToken;
    if (o.kind === 'image' && state.overlayKind === 'image') {
      var b = o.bounds;
      var coords = [[b[0], b[3]], [b[2], b[3]], [b[2], b[1]], [b[0], b[1]]];
      state.overlayKey = key;
      if (!fade) { source.updateImage({ url: o.url, coordinates: coords }); return; }
      setOverlayOpacity(0);
      setTimeout(function () {
        if (token !== state.overlayToken || !map) return;
        source.updateImage({ url: o.url, coordinates: coords });
        setTimeout(applyOverlayOpacity, 80);
      }, 280);
      return;
    }
    // Between a picture, tiles and rivers, or between tile sets: fade out, swap, fade in.
    setOverlayOpacity(0);
    setTimeout(function () {
      if (token !== state.overlayToken || !map) return;
      removeOverlay();
      addOverlay(state.overlay, 0);
      setTimeout(applyOverlayOpacity, 80);
    }, fade ? 280 : 0);
  }

  // ---------------------------------------------------------------- breeze

  var BREEZE_CSS =
    '.ws-breeze{position:absolute;inset:0;z-index:5;pointer-events:none;overflow:hidden;animation:wsBzOut 3.5s ease forwards}' +
    '.ws-breeze .g{position:absolute;left:0;width:62%;border-radius:50%;background:radial-gradient(closest-side,var(--bzc),transparent);' +
    'filter:blur(14px);opacity:0;transform:translateX(-80%);animation:wsGust var(--d,2.4s) cubic-bezier(.4,.05,.3,1) var(--dl,0ms) forwards}' +
    '.ws-breeze .lf{position:absolute;left:0;opacity:0;animation:wsLeaf var(--d,2.6s) cubic-bezier(.45,.05,.35,1) var(--dl,0ms) forwards}' +
    '.ws-breeze .lf svg{width:100%;height:100%;animation:wsSpin var(--sp,.9s) linear infinite;filter:drop-shadow(0 1px 1px rgba(0,0,0,.25))}' +
    '.ws-breeze .tb{position:absolute;left:24%;top:52%;width:86px;height:118px;transform:translate(-50%,-100%);' +
    'animation:wsTb 3s cubic-bezier(.2,.9,.3,1) forwards;filter:drop-shadow(0 6px 10px var(--tws))}' +
    '.ws-breeze .tb svg{width:100%;height:100%;overflow:visible}' +
    '.ws-breeze .tb .rotor{transform-origin:43px 36px;animation:wsRot 3s cubic-bezier(.3,.1,.4,1) forwards}' +
    '.ws-breeze.phone .tb{width:64px;height:88px;left:26%;top:44%}' +
    '@keyframes wsGust{0%{opacity:0;transform:translateX(-80%) scaleY(.7)}25%{opacity:1}70%{opacity:.85}100%{opacity:0;transform:translateX(175%) scaleY(1.15)}}' +
    '@keyframes wsLeaf{0%{opacity:0;transform:translate(-5vw,0)}12%{opacity:1}35%{transform:translate(calc(var(--w)*.32),calc(var(--a)*-1))}' +
    '60%{transform:translate(calc(var(--w)*.6),var(--a))}85%{opacity:1}100%{opacity:0;transform:translate(calc(var(--w)*1.02),calc(var(--a)*-.6))}}' +
    '@keyframes wsSpin{0%{transform:rotate(0) scaleX(1)}50%{transform:rotate(200deg) scaleX(.35)}100%{transform:rotate(360deg) scaleX(1)}}' +
    '@keyframes wsTb{0%{opacity:0;transform:translate(-50%,-92%) scale(.9)}18%{opacity:1;transform:translate(-50%,-100%) scale(1)}72%{opacity:1}100%{opacity:0;transform:translate(-50%,-100%) scale(1)}}' +
    '@keyframes wsRot{from{transform:rotate(0)}to{transform:rotate(760deg)}}' +
    '@keyframes wsBzOut{0%,70%{opacity:1}100%{opacity:0}}';

  function playBreeze() {
    if (!container) return;
    if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    if (!document.getElementById('ws-breeze-style')) {
      var st = document.createElement('style');
      st.id = 'ws-breeze-style';
      st.textContent = BREEZE_CSS;
      document.head.appendChild(st);
    }
    var old = container.querySelector('.ws-breeze');
    if (old) old.remove();
    var W = container.clientWidth, H = container.clientHeight;
    var dark = state.dark;
    var gustColor = dark ? 'rgba(170,200,245,.32)' : 'rgba(150,188,232,.5)';
    var tower = dark ? '#DCE6F4' : '#ffffff';
    var shadow = dark ? 'rgba(0,0,0,.5)' : 'rgba(30,58,110,.55)';
    var leafA = dark ? '#8CC07A' : '#7FB069', leafB = dark ? '#D6B25E' : '#C9A24B';
    var el = document.createElement('div');
    el.className = 'ws-breeze' + (W < 600 ? ' phone' : '');
    el.setAttribute('aria-hidden', 'true');
    el.style.setProperty('--bzc', gustColor);
    el.style.setProperty('--tws', shadow);
    var html = '';
    // Soft gusts: blurred, airy bands that sweep across.
    [[.18, 46, 0, 2.3], [.36, 70, 260, 2.5], [.55, 54, 120, 2.2], [.72, 80, 420, 2.6], [.86, 40, 600, 2.3]].forEach(function (g) {
      html += '<i class="g" style="top:' + (g[0] * H - g[1] / 2) + 'px;height:' + g[1] + 'px;--dl:' + g[2] + 'ms;--d:' + g[3] + 's"></i>';
    });
    // A few leaves carried by the breeze.
    function leaf(color) {
      return '<svg viewBox="0 0 20 20"><path fill="' + color + '" d="M2 18 C 2 8, 9 2, 18 2 C 18 11, 12 18, 2 18 Z"/>' +
        '<path d="M3 17 L 15 5" stroke="rgba(0,0,0,.18)" stroke-width="1" fill="none"/></svg>';
    }
    [[.22, 180, leafA, 2.6, .8, 18], [.41, 520, leafB, 2.4, 1.1, 26], [.6, 320, leafA, 2.8, .7, 14], [.33, 760, leafA, 2.3, .95, 22],
      [.7, 640, leafB, 2.5, 1.2, 16]].forEach(function (l, i) {
      var size = i % 2 ? 11 : 14;
      html += '<span class="lf" style="top:' + (l[0] * H) + 'px;width:' + size + 'px;height:' + size + 'px;--dl:' + l[1] +
        'ms;--d:' + l[3] + 's;--sp:' + l[4] + 's;--a:' + l[5] + 'px;--w:' + W + 'px">' + leaf(l[2]) + '</span>';
    });
    // A turbine that spins up and fades.
    var blade = 'M43 36 C 41 26, 41.6 12, 43.6 2 C 45.4 12, 45.4 26, 43.8 36 Z';
    html += '<div class="tb"><svg viewBox="0 0 86 118"><path fill="' + tower + '" d="M41.2 38 L44.8 38 L46.6 118 L39.4 118 Z"/>' +
      '<g class="rotor"><path fill="' + tower + '" d="' + blade + '"/><path fill="' + tower + '" d="' + blade + '" transform="rotate(120 43 36)"/>' +
      '<path fill="' + tower + '" d="' + blade + '" transform="rotate(240 43 36)"/>' +
      '<circle cx="43" cy="36" r="3.4" fill="' + tower + '" stroke="' + shadow + '" stroke-width=".6"/></g></svg></div>';
    el.innerHTML = html;
    container.insertBefore(el, shield);
    setTimeout(function () { el.remove(); }, 3600);
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
    version: VERSION,

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
        state.attribution = opts.attribution || '';
        attributionControl = new maplibregl.AttributionControl({ compact: true, customAttribution: state.attribution });
        map.addControl(attributionControl, 'bottom-left');
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
      state.overlay = { kind: 'image', url: url, bounds: bounds, opacity: opacity };
      whenLoaded(function () { applyOverlay(had); });
    },

    /** Map tiles instead of a single picture; url has {z}/{x}/{y}; tiles exist up to maxZoom. */
    setTileOverlay: function (url, bounds, opacity, maxZoom) {
      var had = !!state.overlay;
      state.overlay = { kind: 'tiles', url: url, bounds: bounds, opacity: opacity, maxZoom: maxZoom };
      whenLoaded(function () { applyOverlay(had); });
    },

    /**
     * River lines from vector tiles instead of a picture: url has {z}/{x}/{y}; style is a
     * JSON string {sourceLayer, property, min, max, log, colors, widthProperty}: the line
     * colour follows that value on the scale, the width follows widthProperty (mean flow).
     */
    setRiverOverlay: function (url, bounds, opacity, maxZoom, style) {
      var had = !!state.overlay;
      state.overlay = { kind: 'rivers', url: url, bounds: bounds, opacity: opacity, maxZoom: maxZoom, river: JSON.parse(style) };
      whenLoaded(function () { applyOverlay(had); });
    },

    /** Replaces the data credit in the attribution line. */
    setAttribution: function (html) {
      if (html === state.attribution) return;
      state.attribution = html;
      whenLoaded(function () {
        if (attributionControl) map.removeControl(attributionControl);
        attributionControl = new maplibregl.AttributionControl({ compact: true, customAttribution: state.attribution });
        map.addControl(attributionControl, 'bottom-left');
        var corner = container && container.querySelector('.maplibregl-ctrl-bottom-left');
        if (corner) corner.style.bottom = state.attributionBottom + 'px';
      });
    },

    playBreeze: function () { playBreeze(); },

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
      state.attributionBottom = px;
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
      resizeObserver = null; pending = []; state.overlay = null; state.overlayKey = null; state.overlayKind = null;
      attributionControl = null;
    }
  };
})();
