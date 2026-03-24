/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        cr: {
          bg: "#0a0a0a",
          surface: "#111111",
          panel: "#080808",
          border: "rgba(255,255,255,0.06)",
          "border-light": "rgba(255,255,255,0.10)",
          accent: "#ffffff",
          "accent-hover": "#d4d4d4",
          text: "#e5e5e5",
          muted: "#737373",
          green: "#22c55e",
          red: "#ef4444",
          yellow: "#eab308",
          blue: "#60a5fa",
        },
      },
      fontFamily: {
        mono: ["JetBrains Mono", "Fira Code", "Cascadia Code", "monospace"],
        sans: ["Inter", "system-ui", "-apple-system", "sans-serif"],
      },
    },
  },
  plugins: [],
};
