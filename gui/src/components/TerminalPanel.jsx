import { useEffect, useRef } from "react";

export default function TerminalPanel({ logs, t, onClear, progress }) {
  const bottomRef = useRef(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [logs]);

  const colorize = (line) => {
    if (line.startsWith("[+]")) return "text-cr-green";
    if (line.startsWith("[-]")) return "text-cr-red";
    if (line.startsWith("[>]") || line.startsWith("[~]")) return "text-cr-accent";
    if (line.includes("complete") || line.includes("tamamlandi")) return "text-cr-accent";
    return "text-cr-muted";
  };

  return (
    <div className="w-80 bg-cr-panel border-l border-cr-border flex flex-col">
      {/* Header */}
      <div className="flex justify-between items-center px-4 py-3 border-b border-cr-border">
        <span className="text-[11px] text-cr-muted uppercase tracking-wider">
          {t("terminal.title")}
        </span>
        <button
          onClick={onClear}
          className="text-[10px] text-cr-accent hover:text-cr-accent-hover transition"
        >
          {t("terminal.clear")}
        </button>
      </div>

      {/* Log lines */}
      <div className="flex-1 overflow-y-auto px-4 py-3 text-[11px] leading-7 font-mono">
        {logs.map((line, i) => (
          <div key={i} className={colorize(line)}>
            {line}
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      {/* Progress bar */}
      {progress !== null && (
        <div className="px-4 pb-3">
          <div className="flex justify-between text-[11px] text-cr-muted mb-1">
            <span>{t("terminal.progress")}</span>
            <span>{progress}%</span>
          </div>
          <div className="h-1 bg-cr-border rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-cr-accent to-cr-blue rounded-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      )}
    </div>
  );
}
