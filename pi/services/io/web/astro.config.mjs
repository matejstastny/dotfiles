// @ts-check
import { defineConfig } from "astro/config";

// the go service embeds dist/ and serves it, so nothing here is ever deployed
// on its own. directory format keeps /recent working under http.FileServer.
export default defineConfig({
    outDir: "../server/dist",
    build: { format: "directory", assets: "_astro" },
    devToolbar: { enabled: false },
    vite: {
        server: {
            proxy: { "/api": "http://127.0.0.1:8090" },
        },
    },
});
