import tailwindcss from "@tailwindcss/vite";
import { sveltekit } from "@sveltejs/kit/vite";
import { defineConfig } from "vite";
import wasmPack from "vite-plugin-wasm-pack";

export default defineConfig({
    plugins: [wasmPack("../truffle-wasm"), tailwindcss(), sveltekit()],
});
