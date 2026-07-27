#!/usr/bin/env python3
"""Make Godot's generated web export update reliably on iOS home-screen PWAs."""

from __future__ import annotations

import pathlib
import re
import sys


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f"expected one {label} marker, found {text.count(old)}")
    return text.replace(old, new)


def patch_service_worker(path: pathlib.Path) -> None:
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "\tevent.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));",
        "\tevent.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)).then(() => self.skipWaiting()));",
        "service-worker install handler",
    )
    text = replace_once(
        text,
        "\t\treturn ('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable() : Promise.resolve();\n\t}));\n});",
        "\t\treturn ('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable() : Promise.resolve();\n\t}).then(() => self.clients.claim()));\n});",
        "service-worker activate handler",
    )
    old_fetch = """\t\t\t\tevent.respondWith((async () => {\n\t\t\t\t\t// Try to use cache first\n\t\t\t\t\tconst cache = await caches.open(CACHE_NAME);\n\t\t\t\t\tif (isNavigate) {\n\t\t\t\t\t\t// Check if we have full cache during HTML page request.\n\t\t\t\t\t\t/** @type {Response[]} */\n\t\t\t\t\t\tconst fullCache = await Promise.all(FULL_CACHE.map((name) => cache.match(name)));\n\t\t\t\t\t\tconst missing = fullCache.some((v) => v === undefined);\n\t\t\t\t\t\tif (missing) {\n\t\t\t\t\t\t\ttry {\n\t\t\t\t\t\t\t\t// Try network if some cached file is missing (so we can display offline page in case).\n\t\t\t\t\t\t\t\tconst response = await fetchAndCache(event, cache, isCacheable);\n\t\t\t\t\t\t\t\treturn response;\n\t\t\t\t\t\t\t} catch (e) {\n\t\t\t\t\t\t\t\t// And return the hopefully always cached offline page in case of network failure.\n\t\t\t\t\t\t\t\tconsole.error('Network error: ', e); // eslint-disable-line no-console\n\t\t\t\t\t\t\t\treturn caches.match(OFFLINE_URL);\n\t\t\t\t\t\t\t}\n\t\t\t\t\t\t}\n\t\t\t\t\t}\n\t\t\t\t\tlet cached = await cache.match(event.request);\n\t\t\t\t\tif (cached != null) {\n\t\t\t\t\t\tif (ENSURE_CROSSORIGIN_ISOLATION_HEADERS) {\n\t\t\t\t\t\t\tcached = ensureCrossOriginIsolationHeaders(cached);\n\t\t\t\t\t\t}\n\t\t\t\t\t\treturn cached;\n\t\t\t\t\t}\n\t\t\t\t\t// Try network if don't have it in cache.\n\t\t\t\t\tconst response = await fetchAndCache(event, cache, isCacheable);\n\t\t\t\t\treturn response;\n\t\t\t\t})());"""
    new_fetch = """\t\t\t\tevent.respondWith((async () => {\n\t\t\t\t\tconst cache = await caches.open(CACHE_NAME);\n\t\t\t\t\tlet cached = await cache.match(event.request);\n\t\t\t\t\ttry {\n\t\t\t\t\t\t// Prefer the network while online so an installed PWA receives new builds.\n\t\t\t\t\t\tconst response = await fetchAndCache(event, cache, isCacheable || isNavigate);\n\t\t\t\t\t\treturn response;\n\t\t\t\t\t} catch (e) {\n\t\t\t\t\t\tif (cached != null) {\n\t\t\t\t\t\t\tif (ENSURE_CROSSORIGIN_ISOLATION_HEADERS) {\n\t\t\t\t\t\t\t\tcached = ensureCrossOriginIsolationHeaders(cached);\n\t\t\t\t\t\t\t}\n\t\t\t\t\t\t\treturn cached;\n\t\t\t\t\t\t}\n\t\t\t\t\t\tif (isNavigate) {\n\t\t\t\t\t\t\treturn caches.match(OFFLINE_URL);\n\t\t\t\t\t\t}\n\t\t\t\t\t\tthrow e;\n\t\t\t\t\t}\n\t\t\t\t})());"""
    # The generated handler is indented one level less than this readable template.
    old_fetch = old_fetch.replace("\t\t\t\t", "\t\t\t")
    new_fetch = new_fetch.replace("\t\t\t\t", "\t\t\t")
    fetch_pattern = r"\t\t\tevent\.respondWith\(\(async \(\) => \{.*?\n\t\t\t\}\)\(\)\);"
    if len(re.findall(fetch_pattern, text, flags=re.DOTALL)) < 1:
        raise RuntimeError("expected a service-worker fetch handler marker")
    text = re.sub(fetch_pattern, new_fetch, text, count=1, flags=re.DOTALL)
    path.write_text(text, encoding="utf-8")


def patch_html(path: pathlib.Path) -> None:
    text = path.read_text(encoding="utf-8")
    marker = "\t\t<script src=\"index.js\"></script>"
    update_script = """\t\t<script>\n\t\t\t// Ask iOS to check for a newer service worker whenever the PWA launches.\n\t\t\tif ('serviceWorker' in navigator) {\n\t\t\t\tnavigator.serviceWorker.getRegistration().then(function (registration) {\n\t\t\t\t\tif (registration) { registration.update().catch(function () {}); }\n\t\t\t\t}).catch(function () {});\n\t\t\t}\n\t\t</script>\n""" + marker
    text = replace_once(text, marker, update_script, "PWA update bootstrap")
    path.write_text(text, encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch_pwa.py <export-directory>")
    root = pathlib.Path(sys.argv[1])
    patch_service_worker(root / "index.service.worker.js")
    patch_html(root / "index.html")


if __name__ == "__main__":
    main()
