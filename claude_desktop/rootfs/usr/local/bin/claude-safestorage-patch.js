#!/usr/bin/env node
/*
 * Enable Electron safeStorage for Claude Desktop without a system keyring.
 *
 * Claude Desktop persists its auth token with Electron's safeStorage. On Linux that is gated
 * on a backend: the libsecret backend needs a running Secret Service (gnome-keyring), which is
 * intentionally not installed here because it prompts for a keyring password on first boot and
 * blocks the app from launching. The app is therefore launched with --password-store=basic
 * (Electron's built-in fixed-key store: no daemon, no prompt).
 *
 * That alone is not enough. Electron refuses the `basic_text` backend unless the *application*
 * explicitly opts in by calling safeStorage.setUsePlainTextEncryption(true) before the app is
 * ready, and Claude Desktop never calls it. So isEncryptionAvailable() stays false, the token is
 * never persisted, and the user is asked to sign in again on every start. There is no equivalent
 * command-line switch, and NODE_OPTIONS=--require is ignored by packaged Electron apps, so the
 * opt-in has to be injected into the app's own main bundle.
 *
 * This script does that inside app.asar. It is idempotent (marker-guarded) and re-applied on
 * every boot, because 81-claude_update.sh apt-upgrades claude-desktop and a new package ships a
 * fresh, unpatched app.asar.
 *
 * Failure policy: refuse rather than guess. An unpatched app still runs, it just forgets the
 * sign-in; a corrupted app.asar would not start at all. Every unexpected shape is a hard exit
 * that leaves the original archive untouched.
 *
 * asar layout (all little-endian):
 *   [0]  uint32  = 4               size of the next field
 *   [4]  uint32  = headerBufLen    size of the header pickle
 *   [8]  uint32  = payloadSize     4 + headerString length, 4-byte aligned
 *   [12] uint32  = headerStrLen    exact JSON length
 *   [16] utf8    = headerString    JSON file tree, padded to a 4-byte boundary
 *   then file bodies; each node's "offset" is relative to the end of the header.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ASAR = process.argv[2] || '/usr/lib/claude-desktop/resources/app.asar';
const MARKER = 'CLAUDE_ADDON_SAFESTORAGE_PATCH';
const PATCH =
  `/*${MARKER}*/try{require("electron").safeStorage.setUsePlainTextEncryption(true);}` +
  `catch(e){try{console.error("[claude_desktop addon] safeStorage opt-in failed:",e&&e.message);}catch(_){}}`;

const log = (m) => process.stdout.write(`${m}\n`);
const fail = (m) => {
  process.stderr.write(`${m}\n`);
  process.exit(1);
};

const alignInt = (i, a) => i + ((a - (i % a)) % a);
const sha256 = (b) => crypto.createHash('sha256').update(b).digest('hex');

function readArchive(file) {
  const buf = fs.readFileSync(file);
  if (buf.length < 16 || buf.readUInt32LE(0) !== 4) fail(`Not an asar archive: ${file}`);
  const headerBufLen = buf.readUInt32LE(4);
  const payloadSize = buf.readUInt32LE(8);
  const headerStrLen = buf.readUInt32LE(12);
  const contentBase = 8 + headerBufLen;
  if (headerBufLen !== 4 + payloadSize || payloadSize !== 4 + alignInt(headerStrLen, 4)) {
    fail(`Corrupt asar header pickle in ${file}`);
  }
  if (16 + headerStrLen > buf.length || contentBase > buf.length) {
    fail(`Corrupt asar: header extends past end of ${file}`);
  }
  let header;
  try {
    header = JSON.parse(buf.toString('utf8', 16, 16 + headerStrLen));
  } catch (e) {
    fail(`Corrupt asar: header is not valid JSON (${e.message})`);
  }
  return { buf, header, contentBase };
}

/* Every packed leaf, as [path, node]. Nodes flagged `unpacked` live in app.asar.unpacked/ and
 * `link` nodes are symlinks — neither has bytes inside the archive, so both are carried through
 * untouched and skipped here. */
function packedLeaves(header) {
  const out = [];
  (function walk(dir, prefix) {
    for (const [name, node] of Object.entries(dir.files)) {
      const p = prefix ? `${prefix}/${name}` : name;
      if (node.files) walk(node, p);
      else if (!node.unpacked && typeof node.link !== 'string') out.push([p, node]);
    }
  })(header, '');
  return out;
}

/* Offsets are decimal strings and can exceed 2^31; reject anything that is not a plain, exact,
 * in-bounds extent rather than letting parseInt("12junk") or NaN silently slice the wrong bytes. */
function extentOf(ar, node, where) {
  if (!/^\d+$/.test(String(node.offset))) fail(`Bad offset for ${where}: ${node.offset}`);
  const off = Number(node.offset);
  const size = node.size;
  if (!Number.isSafeInteger(off)) fail(`Offset out of safe range for ${where}`);
  if (!Number.isSafeInteger(size) || size < 0) fail(`Bad size for ${where}: ${size}`);
  const start = ar.contentBase + off;
  const end = start + size;
  if (end > ar.buf.length) fail(`Extent of ${where} runs past end of archive`);
  return { start, end };
}

const bodyOf = (ar, node, where) => {
  const { start, end } = extentOf(ar, node, where);
  return ar.buf.subarray(start, end);
};

function resolve(header, relPath) {
  let node = header;
  for (const part of relPath.split('/')) {
    if (!node.files || !node.files[part]) return null;
    node = node.files[part];
  }
  return node;
}

/* Matches @electron/asar: whole-file hash plus one hash per blockSize chunk. An empty file has
 * an empty block list, not a single block over zero bytes. */
function integrityOf(buf, blockSize) {
  const blocks = [];
  for (let i = 0; i < buf.length; i += blockSize) {
    blocks.push(sha256(buf.subarray(i, Math.min(i + blockSize, buf.length))));
  }
  return { algorithm: 'SHA256', hash: sha256(buf), blockSize, blocks };
}

/* Insert the opt-in after the bundle's leading "use strict" directive. It must go *after* it: a
 * directive prologue only takes effect as the very first statement, so prepending would silently
 * drop the whole main process out of strict mode.
 *
 * Returns null — meaning "refuse to patch" — for anything that is not unambiguously a directive.
 * `"use strict" + x` is an expression, not a directive, and injecting into it would produce a
 * syntax error, so the directive is only accepted when it is terminated by its own semicolon, a
 * line break, or end of input. */
function applyPatch(source) {
  const m = /^\s*(['"])use strict\1(;?)/.exec(source);
  if (!m) return null;
  const rest = source.slice(m[0].length);
  const terminated = m[2] === ';' || rest === '' || /^[\r\n]/.test(rest);
  if (!terminated) return null;
  // Supply the terminator when the directive relied on ASI; without it the injected code would
  // continue the string-literal expression instead of following it.
  const sep = m[2] === ';' ? '' : ';';
  return source.slice(0, m[0].length) + sep + PATCH + rest;
}

function writeAll(fd, buf) {
  let off = 0;
  while (off < buf.length) off += fs.writeSync(fd, buf, off, buf.length - off);
}

/* Re-read the rebuilt archive from disk and prove it is sound before it replaces a working one.
 * A short or truncated write late in the file would otherwise still pass a marker-only check,
 * because the main bundle sits near the front. */
function verifyRebuilt(file, mainRel, expectedLeafCount) {
  const ar = readArchive(file);
  const leaves = packedLeaves(ar.header);
  if (leaves.length !== expectedLeafCount) {
    fail(`Rebuilt archive has ${leaves.length} packed entries, expected ${expectedLeafCount}`);
  }
  let maxEnd = ar.contentBase;
  for (const [p, node] of leaves) {
    const { end } = extentOf(ar, node, p);
    if (end > maxEnd) maxEnd = end;
  }
  if (maxEnd !== ar.buf.length) {
    fail(`Rebuilt archive is truncated or has ${ar.buf.length - maxEnd} trailing bytes`);
  }
  const mainNode = resolve(ar.header, mainRel);
  if (!mainNode) fail(`Rebuilt archive lost its main entry ${mainRel}`);
  const body = bodyOf(ar, mainNode, mainRel);
  if (!body.toString('utf8').includes(MARKER)) fail('Rebuilt archive is missing the patch marker');
  if (mainNode.integrity && sha256(body) !== mainNode.integrity.hash) {
    fail('Rebuilt archive has a stale integrity hash for the main entry');
  }
}

function main() {
  if (!fs.existsSync(ASAR)) fail(`Missing ${ASAR}`);

  const ar = readArchive(ASAR);

  const pkgNode = resolve(ar.header, 'package.json');
  if (!pkgNode) fail('app.asar has no package.json');
  const pkg = JSON.parse(bodyOf(ar, pkgNode, 'package.json').toString('utf8'));
  const mainRel = pkg.main;
  if (!mainRel) fail('package.json has no "main" entry');

  const mainNode = resolve(ar.header, mainRel);
  if (!mainNode) fail(`main entry not found in archive: ${mainRel}`);
  if (mainNode.unpacked) fail(`main entry ${mainRel} is unpacked; refusing to patch`);
  if (pkg.type === 'module') fail(`main entry ${mainRel} is ESM; this patcher emits CommonJS`);

  const original = bodyOf(ar, mainNode, mainRel).toString('utf8');
  if (original.includes(MARKER)) {
    log(`Already patched: ${mainRel}`);
    return;
  }

  const patchedSource = applyPatch(original);
  if (patchedSource === null) {
    fail(`${mainRel} does not begin with a recognized "use strict" directive; refusing to patch`);
  }
  const patched = Buffer.from(patchedSource, 'utf8');

  /* Rebuild: copy every packed body in tree order, substituting the patched main entry, and
   * reassign offsets as we go. asar headers store a byte offset and length per file, so content
   * cannot simply grow in place. */
  const leaves = packedLeaves(ar.header);
  const chunks = [];
  let offset = 0;
  let patchedCount = 0;

  for (const [p, node] of leaves) {
    const isMain = node === mainNode;
    const body = isMain ? patched : bodyOf(ar, node, p);
    node.offset = String(offset);
    node.size = body.length;
    if (isMain && node.integrity) {
      node.integrity = integrityOf(body, node.integrity.blockSize || 4 * 1024 * 1024);
    }
    offset += body.length;
    chunks.push(body);
    if (isMain) patchedCount++;
  }
  if (patchedCount !== 1) fail(`expected to rewrite exactly 1 main entry, rewrote ${patchedCount}`);

  const headerString = JSON.stringify(ar.header);
  const strLen = Buffer.byteLength(headerString);
  const payloadSize = 4 + alignInt(strLen, 4);
  const headerBufLen = 4 + payloadSize;

  const prefix = Buffer.alloc(16 + alignInt(strLen, 4));
  prefix.writeUInt32LE(4, 0);
  prefix.writeUInt32LE(headerBufLen, 4);
  prefix.writeUInt32LE(payloadSize, 8);
  prefix.writeUInt32LE(strLen, 12);
  prefix.write(headerString, 16, 'utf8');

  /* Write beside the target and rename, so an interrupted run can never leave a torn app.asar.
   * The temp name carries the pid so two runs cannot share it, and it is removed on every
   * failure path before the rename. */
  const dir = path.dirname(ASAR);
  const tmp = path.join(dir, `.${path.basename(ASAR)}.addon-tmp.${process.pid}`);
  const mode = fs.statSync(ASAR).mode & 0o7777;

  try {
    const out = fs.openSync(tmp, 'wx', mode);
    try {
      writeAll(out, prefix);
      for (const c of chunks) writeAll(out, c);
      fs.fsyncSync(out); // durable before it becomes the live archive
    } finally {
      fs.closeSync(out);
    }
    fs.chmodSync(tmp, mode);
    verifyRebuilt(tmp, mainRel, leaves.length);
    fs.renameSync(tmp, ASAR);
  } catch (e) {
    try {
      fs.unlinkSync(tmp);
    } catch (_) {
      /* nothing to clean up */
    }
    fail(`Rebuild failed, original left untouched: ${e.message}`);
  }

  /* Sync the directory so the rename itself survives a crash, not just the file's contents. */
  try {
    const dfd = fs.openSync(dir, 'r');
    fs.fsyncSync(dfd);
    fs.closeSync(dfd);
  } catch (_) {
    /* best effort */
  }

  log(`Patched ${mainRel} in ${ASAR} (safeStorage plain-text opt-in)`);
}

main();
