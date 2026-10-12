// Lets static hosts with per-file size limits serve the engine as index.wasm.gz.
// If index.wasm.gz exists it is downloaded and unpacked in the browser,
// otherwise the normal index.wasm is used.
(function () {
	var orig = window.fetch.bind(window);
	window.fetch = function (input, init) {
		var url = typeof input === "string" ? input : (input && input.url) || "";
		if (/\.wasm(\?.*)?$/.test(url) && typeof DecompressionStream !== "undefined") {
			var gz = url.replace(/\.wasm(\?.*)?$/, ".wasm.gz$1");
			return orig(gz, init).then(function (r) {
				if (!r.ok) return orig(input, init);
				return r.arrayBuffer().then(function (ab) {
					var b = new Uint8Array(ab);
					if (!(b[0] === 0x1f && b[1] === 0x8b)) {
						return new Response(b, { status: 200, headers: { "Content-Type": "application/wasm", "Content-Length": String(b.length) } });
					}
					var s = new Blob([b]).stream().pipeThrough(new DecompressionStream("gzip"));
					return new Response(s).arrayBuffer().then(function (out) {
						return new Response(out, { status: 200, headers: { "Content-Type": "application/wasm", "Content-Length": String(out.byteLength) } });
					});
				});
			}).catch(function () { return orig(input, init); });
		}
		return orig(input, init);
	};
})();
