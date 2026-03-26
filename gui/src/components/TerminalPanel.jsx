import { useEffect, useRef } from "react";

export default function TerminalPanel({ logs, t, onClear, progress }) {
  const bottomRef = useRef(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [logs]);

  const colorize = (line) => {
    if (line.startsWith("[+]")) return "text-cr-green font-semibold";
    if (line.startsWith("[-]")) return "text-cr-red font-semibold";
    if (line.startsWith("[>]") || line.startsWith("[~]")) return "text-cr-accent";
    if (line.includes("complete") || line.includes("tamamlandi")) return "text-cr-accent font-semibold";
    return "text-[#a0a0a0]";
  };

  return (
    <div className="w-96 flex flex-col border-l border-[rgba(255,255,255,0.08)]" style={{ backgroundColor: "#0d0d10" }}>
      {/* Header */}
      <div className="flex justify-between items-center px-5 py-3.5 border-b border-[rgba(255,255,255,0.08)]">
        <span className="text-[12px] text-cr-muted uppercase tracking-wider font-semibold">
          {t("terminal.title")}
        </span>
        <button
          onClick={onClear}
          className="text-[12px] text-cr-accent hover:text-white transition font-medium px-2 py-0.5 rounded hover:bg-white/5"
        >
          {t("terminal.clear")}
        </button>
      </div>

      {/* Log lines */}
      <div className="flex-1 overflow-y-auto px-5 py-3 text-[13px] leading-8 font-mono">
        {logs.map((line, i) => (
          <div key={i} className={colorize(line)}>
            {line}
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      {/* Progress bar */}
      {progress !== null && (
        <div className="px-5 pb-4">
          <div className="flex justify-between text-[12px] text-cr-muted mb-1.5 font-medium">
            <span>{t("terminal.progress")}</span>
            <span>{progress}%</span>
          </div>
          <div className="h-1.5 bg-[rgba(255,255,255,0.06)] rounded-full overflow-hidden">
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
