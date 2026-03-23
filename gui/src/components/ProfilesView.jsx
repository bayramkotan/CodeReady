import { useState } from "react";

export default function ProfilesView({ profiles, t, onApply }) {
  const [selectedIds, setSelectedIds] = useState(new Set());
  const lang = t("appName") === "CODEREADY" ? "en" : "tr"; // simple detect

  const toggle = (id) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const profileName = (p) => (lang === "tr" ? p.name_tr : p.name);

  return (
    <div className="flex-1 overflow-y-auto px-6 py-5">
      <div className="text-[12px] text-cr-muted uppercase tracking-wider mb-2">
        {t("profiles.title")}
      </div>
      <div className="text-[12px] text-cr-muted mb-5">
        {t("profiles.subtitle")}
      </div>

      {/* Profile grid */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        {profiles.map((p) => (
          <div
            key={p.id}
            onClick={() => toggle(p.id)}
            className={`px-4 py-3 rounded-lg border cursor-pointer transition ${
              selectedIds.has(p.id)
                ? "border-cr-accent bg-[#0f2a2a]"
                : "border-cr-border-light bg-cr-surface hover:border-cr-muted"
            }`}
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-[13px] text-cr-text font-medium">
                {profileName(p)}
              </span>
              <span className="text-[11px] text-cr-muted">#{p.id}</span>
            </div>
            <div className="flex flex-wrap gap-1">
              {[...p.languages.slice(0, 3), ...p.ides.slice(0, 1)].map((item) => (
                <span
                  key={item}
                  className="text-[10px] px-2 py-0.5 rounded bg-cr-bg text-cr-muted border border-cr-border"
                >
                  {item}
                </span>
              ))}
              {p.languages.length + p.ides.length > 4 && (
                <span className="text-[10px] px-2 py-0.5 text-cr-muted">
                  +{p.languages.length + p.ides.length + p.frameworks.length + p.tools.length - 4}
                </span>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Apply button */}
      <button
        onClick={() => onApply([...selectedIds])}
        disabled={selectedIds.size === 0}
        className="px-5 py-2.5 bg-cr-accent text-cr-bg text-[13px] font-semibold rounded-md hover:bg-cr-accent-hover transition disabled:opacity-40 disabled:cursor-not-allowed"
      >
        {t("profiles.apply")} {selectedIds.size > 0 && `(${selectedIds.size})`}
      </button>
    </div>
  );
}
