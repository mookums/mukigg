import { defineConfig } from 'vite';
import compression from 'vite-plugin-compression';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
    plugins: [
        tailwindcss(),
        compression({
            algorithm: 'gzip',
            threshold: 0,
            deleteOriginFile: true,
        }),
    ],
    build: {
        cssCodeSplit: false,
        outDir: 'src/bundle',
        lib: {
            entry: 'src/web/index.js',
            name: 'mukigg',
            formats: ['iife'],
            fileName: () => 'bundle.js'
        },
        rollupOptions: {
            output: {
                assetFileNames: 'bundle.[ext]',
            }
        }
    },
});
