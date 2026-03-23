import { useState } from "react";

export default function ScanView({ items, t, onInstall }) {
  const [selected, setSelected] = useState(new Set());

  const toggle = (name) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(name) ? next.delete(name) : next.add(name);
      return next;
    });
  };

  const selectAllMissing = () => {
    const missing = items.filter((i) => !i.installed).map((i) => i.name);
    setSelected(new Set(missing));
  };

  const categories = [...new Set(items.map((i) => i.category))];
  const categoryLabels = {
    language: t("categories.language"),
    ide: t("categories.ide"),
    framework: t("categories.framework"),
    tool: t("categories.tool"),
  };

  const installed = items.filter((i) => i.installed).length;
  const missing = items.length - installed;

  return (
    <div className="flex-1 overflow-y-auto px-6 py-5">
      {categories.map((cat) => {
        const catItems = items.filter((i) => i.category === cat);
        if (catItems.length === 0) return null;

        return (
          <div key={cat} className="mb-6">
            <div className="text-[12px] text-cr-muted uppercase tracking-wider mb-3">
              {categoryLabels[cat] || cat}
            </div>

            <div className="flex flex-col gap-1.5">
              {catItems.map((item) => (
                <div
                  key={item.name}
                  onClick={() => !item.installed && toggle(item.name)}
                  className={`flex items-center justify-between px-3 py-2 rounded-md bg-cr-surface border-l-[3px] cursor-pointer transition hover:bg-[#1a1a40] ${
                    item.installed ? "border-cr-green" : "border-cr-red"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    {!item.installed && (
                      <div
                        className={`w-4 h-4 rounded border flex items-center justify-center text-[10px] transition ${
                          selected.has(item.name)
                            ? "bg-cr-accent border-cr-accent text-cr-bg"
                            : "border-cr-border-light text-transparent"
                        }`}
                      >
                        ✓
                      </div>
                    )}
                    <span className="text-[13px] text-cr-text">{item.name}</span>
                  </div>
                  <span
                    className={`text-[12px] ${
                      item.installed ? "text-cr-green" : "text-cr-red"
                    }`}
                  >
                    {item.installed
                      ? item.version === "found"
                        ? t("scan.found")
                        : item.version
                      : t("scan.notInstalled")}
                  </span>
                </div>
              ))}
            </div>
          </div>
        );
      })}

      {/* Stats */}
      <div className="flex gap-5 text-[12px] mt-2 mb-4">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-cr-green" />
          <span className="text-cr-muted">
            {installed} {t("scan.installed")}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-cr-red" />
          <span className="text-cr-muted">
            {missing} {t("scan.notInstalled")}
          </span>
        </div>
      </div>

      {/* Action buttons */}
      <div className="flex gap-3">
        <button
          onClick={() => onInstall([...selected])}
          disabled={selected.size === 0}
          className="px-5 py-2.5 bg-cr-accent text-cr-bg text-[13px] font-semibold rounded-md hover:bg-cr-accent-hover transition disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {t("scan.installSelected")} {selected.size > 0 && `(${selected.size})`}
        </button>
        <button
          onClick={selectAllMissing}
          className="px-5 py-2.5 text-cr-accent text-[13px] border border-cr-border-light rounded-md hover:bg-cr-surface transition"
        >
          {t("scan.selectAll")}
        </button>
      </div>
    </div>
  );
}
