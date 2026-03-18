# BentoPDF

Privacy-first PDF toolkit with 50+ tools. All processing happens client-side in the browser — files never leave your device.

## Usage

After starting the add-on, open the web UI via the **Open Web UI** button or navigate to `https://<HA_IP>:8443`.

No configuration is required to get started.

## Browser Security Warning (Expected)

When you first open the add-on, your browser will show a security warning similar to:

> **Warning: Potential Security Risk Ahead** — Firefox detected a potential security threat…

or in Chrome/Edge:

> **Your connection is not private** — NET::ERR_CERT_AUTHORITY_INVALID

**This is expected and safe to proceed.** Here is why it happens and what to do:

### Why does this happen?

The add-on serves content over HTTPS using a **self-signed TLS certificate** generated locally on your Home Assistant instance. This certificate was not issued by a public Certificate Authority (CA) that browsers trust by default — it was created specifically for your installation.

HTTPS is required because the office file conversion feature (Word, Excel, PowerPoint → PDF) uses LibreOffice compiled to WebAssembly, which requires `SharedArrayBuffer`. Browsers only allow `SharedArrayBuffer` on pages served over a secure context. Plain `http://` over a LAN IP does not qualify, but `https://` does — even with a self-signed certificate.

### What to do

Accept the warning once in your browser:

- **Firefox**: Click **Advanced…** → **Accept the Risk and Continue**
- **Chrome / Edge**: Click **Advanced** → **Proceed to … (unsafe)**
- **Safari**: Click **Show Details** → **visit this website**

You only need to do this once per browser. After accepting, the browser remembers the exception for this add-on.

### Is it actually safe?

Yes. The certificate secures the connection between **your browser and your own Home Assistant instance on your local network**. No data leaves your device — all PDF processing is done entirely in the browser. The warning exists only because the certificate was not signed by a global CA, not because anything malicious is happening.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `log_level` | `info` | Log verbosity: `info`, `debug`, `warn`, `error` |

## Support

For issues with the add-on packaging, open an issue at [github.com/ToledoEM/BentoPDF_HA_app](https://github.com/ToledoEM/BentoPDF_HA_app).

For issues with BentoPDF itself, visit [github.com/alam00000/bentopdf](https://github.com/alam00000/bentopdf).
