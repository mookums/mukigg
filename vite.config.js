import { defineConfig } from 'vite';
import compression from 'vite-plugin-compression';

export default defineConfig({
    plugins: [
        compression({
            algorithm: 'gzip',
            threshold: 0,
        }),
    ],
    build: {
        outDir: 'src/bundle',
        //emptyOutDir: true,
        rollupOptions: {
            input: 'src/index.js',
            output: {
                format: 'iife',
                entryFileNames: 'bundle.js',
            },
        },
    },
});

