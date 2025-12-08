import path from "path";
import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    plugins: [react(), tailwindcss()],
      server: {
        port: parseInt(env.PORT || '9000'),
        host: '0.0.0.0',
        proxy: {
          "/api": {
            target: env.VITE_API_URL || "http://localhost:8000",
          },
        },
      },
      resolve: {
        alias: {
          "@": path.resolve(__dirname, "./src"),
        },
      },
  };
});
