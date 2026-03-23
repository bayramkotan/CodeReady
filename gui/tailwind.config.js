/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        cr: {
          bg: "#0f0f23",
          surface: "#131330",
          panel: "#0a0a1a",
          border: "#1a1a3e",
          "border-light": "#2a2a4a",
          accent: "#5eead4",
          "accent-hover": "#2dd4bf",
          text: "#e2e8f0",
          muted: "#7a7a9a",
          green: "#28c840",
          red: "#ff5f57",
          yellow: "#febc2e",
          blue: "#38bdf8",
        },
      },
      fontFamily: {
        mono: ["JetBrains Mono", "Fira Code", "Cascadia Code", "monospace"],
      },
    },
  },
  plugins: [],
};
