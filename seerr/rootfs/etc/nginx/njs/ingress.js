/*
 * Repair the query string of a Home Assistant ingress request.
 *
 * Supervisor proxies ingress traffic with `params=request.query`
 * (supervisor/api/ingress.py), so aiohttp/yarl re-encodes an already-decoded
 * query string on the way to this add-on. yarl's "safe" set is much wider than
 * the one Seerr's express-openapi-validator will accept: yarl emits a space as
 * "+" and passes ":", "/", "?", "@", "!", "$", "'", "(", ")", "*" and ","
 * through bare, while the validator checks the raw, still-encoded value against
 *
 *     RESERVED_CHARS = /[\:\/\?#\[\]@!\$&\'()\*\+,;=]/
 *
 * and answers 400 "Parameter '<name>' must be url encoded". Every search for a
 * title containing a space or punctuation therefore fails - "Monsters, Inc.",
 * "Ocean's Eleven", "Mission: Impossible" - which Seerr's UI reports as a
 * 500. The same requests succeed on the directly published port 5055, which
 * does not pass through Supervisor.
 *
 * "?" deserves a note: the validator strips one with `qs.replace('?', '')`
 * before testing, so a single bare "?" slips through by accident and only a
 * second one ("Who? What?") produces the 400. It is encoded here regardless.
 *
 * Re-encoding those characters here is lossless, because yarl only ever emits
 * them bare when they were literal characters of the value: anything the user
 * actually typed that is ambiguous comes through already percent-encoded
 * (a typed "+" arrives as "%2B", "&" as "%26", "=" as "%3D").
 *
 * "&" and "=" are deliberately NOT re-encoded: they are the query string's own
 * separators, so a bare one is always structural.
 */

/*
 * Every character of the validator's RESERVED_CHARS except "&" and "=", which
 * are the query string's own separators and are handled above. Deriving the
 * set from what the validator rejects - rather than from what yarl currently
 * emits bare - keeps this correct if either side changes its safe set.
 */
var NEEDS_ENCODING = /[:\/?#\[\]@!$'()*,;]/g;

function encodePart(part) {
    return part
        /* yarl encodes a space as "+"; a literal "+" arrives as "%2B". */
        .replace(/\+/g, "%20")
        .replace(NEEDS_ENCODING, function (c) {
            return "%" + c.charCodeAt(0).toString(16).toUpperCase();
        });
}

/*
 * The cache-busting marker servers/ingress.conf inserts in front of every
 * rewritten "/_next" path, e.g. "/ha-3-4-1-3/_next/static/chunks/x.js". It
 * gives each add-on release its own asset URLs - Seerr serves /_next/static/ as
 * immutable for a year and sub_filter strips the validators, so identical URLs
 * would pin the rewritten bundle in the browser forever. Seerr knows nothing
 * about the marker, so it is removed again here, on the way in.
 *
 * Any marker is accepted, not just the one this container serves: a tab opened
 * before an add-on update keeps requesting its dynamic chunks under the marker
 * it was handed, and those have to keep working until it is reloaded. The
 * lookahead keeps a real Seerr path that merely starts with "ha-" untouched.
 */
var ASSET_TAG = /^\/ha-[0-9A-Za-z-]+(?=\/_next(\/|$))/;

/*
 * Returns the request URI with the path untouched byte-for-byte apart from the
 * cache-busting marker, and only the query string repaired. Used as the
 * proxy_pass target.
 */
function uri(r) {
    var raw = r.variables.request_uri.replace(ASSET_TAG, "");
    var split = raw.indexOf("?");

    if (split < 0) {
        return raw;
    }

    var path = raw.substring(0, split);
    var args = raw.substring(split + 1);

    /* A bare trailing "?" is forwarded as-is, so the URI stays byte-for-byte. */
    if (args === "") {
        return raw;
    }

    var repaired = args
        .split("&")
        .map(function (pair) {
            var eq = pair.indexOf("=");
            if (eq < 0) {
                return encodePart(pair);
            }
            return encodePart(pair.substring(0, eq)) + "=" + encodePart(pair.substring(eq + 1));
        })
        .join("&");

    return path + "?" + repaired;
}

export default { uri };
