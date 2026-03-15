# Vue.js Docs - Offline Docker

Full offline build of the [Vue.js documentation](https://vuejs.org), packaged as a Docker image. No internet connection required after pulling the image.

## Quick Start

### From Docker Hub

```bash
docker pull a0533057932/vue-docs-offline:latest
docker run -d -p 8080:80 --name vue-docs a0533057932/vue-docs-offline:latest
```

Open http://localhost:8080

### From GitHub Container Registry

```bash
docker pull ghcr.io/elishteinman/vue-docs-offline:latest
docker run -d -p 8080:80 --name vue-docs ghcr.io/elishteinman/vue-docs-offline:latest
```

Open http://localhost:8080

### Stop / Remove

```bash
docker stop vue-docs
docker rm vue-docs
```

## Build From Source

```bash
git clone https://github.com/EliShteinman/vue-docs-offline.git
cd vue-docs-offline
docker compose up -d
```

Open http://localhost:8080

## What's Included

- Full Vue.js 3 documentation (guides, API reference, tutorial, examples)
- Interactive REPL with locally bundled Vue runtime
- VitePress local search (replaces Algolia)
- All CDN dependencies downloaded locally (Vue, marked, lodash-es, js-confetti)

## What's Removed

| Component | Reason |
|---|---|
| Fathom Analytics | External tracking service |
| Bitterbrains Ads | External ad network |
| Carbon Ads | External ad network |
| Algolia DocSearch | Requires external API calls |

Algolia is replaced with VitePress built-in local search.

## Platform Support

| Architecture | Supported |
|---|---|
| linux/amd64 | Yes |
| linux/arm64 | Yes |

## Configuration

Change the port by modifying the `-p` flag:

```bash
docker run -d -p 3000:80 a0533057932/vue-docs-offline:latest
```

## Tags

| Tag | Description |
|---|---|
| `latest` | Most recent build |
| `1.0.0` | First stable release |

## Links

- [Docker Hub](https://hub.docker.com/r/a0533057932/vue-docs-offline)
- [GitHub](https://github.com/EliShteinman/vue-docs-offline)

## License

The Vue.js documentation is licensed under [MIT](https://opensource.org/licenses/MIT).
This Docker packaging is an independent community contribution.
