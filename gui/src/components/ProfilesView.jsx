import { useState } from "react";

export default function ProfilesView({ profiles, t, onApply }) {
  const [selectedIds, setSelectedIds] = useState(new Set());
  const lang = t("appName") === "CODEREADY" ? "en" : "tr";

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
      <div className="text-[14px] text-white uppercase tracking-wider mb-2 font-semibold">
        {t("profiles.title")}
      </div>
      <div className="text-[13px] text-[#a0a0a0] mb-5">
        {t("profiles.subtitle")}
      </div>

      {/* Profile grid */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        {profiles.map((p) => (
          <div
            key={p.id}
            onClick={() => toggle(p.id)}
            className={`px-5 py-4 rounded-lg border cursor-pointer transition ${
              selectedIds.has(p.id)
                ? "border-blue-500/40 bg-blue-500/8"
                : "border-[rgba(255,255,255,0.08)] bg-[rgba(255,255,255,0.02)] hover:border-[rgba(255,255,255,0.15)] hover:bg-[rgba(255,255,255,0.04)]"
            }`}
          >
            <div className="flex items-center justify-between mb-2.5">
              <span className={`text-[14px] font-semibold ${selectedIds.has(p.id) ? "text-white" : "text-[#d4d4d4]"}`}>
                {profileName(p)}
              </span>
              <span className="text-[12px] text-cr-muted font-mono">#{p.id}</span>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {[...p.languages.slice(0, 3), ...p.ides.slice(0, 1)].map((item) => (
                <span
                  key={item}
                  className="text-[11px] px-2.5 py-1 rounded-md bg-[rgba(255,255,255,0.04)] text-[#a0a0a0] border border-[rgba(255,255,255,0.06)] font-medium"
                >
                  {item}
                </span>
              ))}
              {p.languages.length + p.ides.length > 4 && (
                <span className="text-[11px] px-2 py-1 text-cr-muted font-medium">
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
        className="px-6 py-3 bg-white text-black text-[14px] font-semibold rounded-lg hover:bg-gray-200 transition disabled:opacity-30 disabled:cursor-not-allowed"
      >
        {t("profiles.apply")} {selectedIds.size > 0 && `(${selectedIds.size})`}
      </button>
    </div>
  );
}
