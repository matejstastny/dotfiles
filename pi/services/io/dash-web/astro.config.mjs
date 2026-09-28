// @ts-check
import { defineConfig } from "astro/config";

// the go service embeds dist/ and serves it, so nothing here is ever deployed
// on its own.
export default defineConfig({
    outDir: "../dash-server/dist",
    build: { format: "directory", assets: "_astro" },
    devToolbar: { enabled: false },
    server: { port: 4323 },
    vite: {
        server: {
            proxy: { "/api": "http://127.0.0.1:8092" },
        },
    },
});
