const IS_TAURI = typeof window !== "undefined" && window.__TAURI_INTERNALS__;

let appWindow = null;
if (IS_TAURI) {
  import("@tauri-apps/api/window").then((m) => {
    appWindow = m.getCurrentWindow();
  });
}

export default function TitleBar({ lang, onToggleLang }) {
  return (
    <div
      data-tauri-drag-region
      className="flex items-center justify-between px-4 py-2.5 bg-[#1a1a2e] border-b border-cr-border-light"
    >
      {/* Traffic lights (Tauri only) */}
      <div className="flex gap-2">
        {IS_TAURI ? (
          <>
            <button
              onClick={() => appWindow?.close()}
              className="w-3 h-3 rounded-full bg-cr-red hover:brightness-110 transition"
            />
            <button
              onClick={() => appWindow?.minimize()}
              className="w-3 h-3 rounded-full bg-cr-yellow hover:brightness-110 transition"
            />
            <button
              onClick={() => appWindow?.toggleMaximize()}
              className="w-3 h-3 rounded-full bg-cr-green hover:brightness-110 transition"
            />
          </>
        ) : (
          <span className="text-[11px] text-cr-accent">WEB MODE</span>
        )}
      </div>

      {/* Version */}
      <span className="text-xs text-cr-muted">CodeReady v2.1.0</span>

      {/* Language toggle */}
      <div className="flex gap-3 text-xs">
        <button
          onClick={() => onToggleLang("en")}
          className={`transition ${lang === "en" ? "text-cr-accent" : "text-cr-muted hover:text-cr-text"}`}
        >
          EN
        </button>
        <button
          onClick={() => onToggleLang("tr")}
          className={`transition ${lang === "tr" ? "text-cr-accent" : "text-cr-muted hover:text-cr-text"}`}
        >
          TR
        </button>
      </div>
    </div>
  );
}
