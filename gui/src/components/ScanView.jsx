import { useState } from "react";

// Categories that support local/global choice
const SCOPE_CATEGORIES = new Set(["framework", "tool"]);

// Items that only make sense as global (system-level)
const GLOBAL_ONLY = new Set([
  "Git", "Docker", "kubectl", "Helm", "Terraform",
  "Scoop", "Chocolatey", "Homebrew", "Flatpak", "Nix", "Snap", "winget",
  "npm", "Yarn", "pnpm", "Bun", "Conda", "pipx", "Poetry", "uv", "VenvStudio",
]);

export default function ScanView({ items, t, onInstall, onRescan, scanning, installing, missingPkgManagers = [] }) {
  const [selected, setSelected] = useState(new Set());
  const [scopes, setScopes] = useState({}); // { itemName: "global" | "local" }
  const [pkgBannerDismissed, setPkgBannerDismissed] = useState(false);

  const toggle = (name) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(name) ? next.delete(name) : next.add(name);
      return next;
    });
  };

  const toggleScope = (e, name) => {
    e.stopPropagation();
    setScopes((prev) => ({
      ...prev,
      [name]: prev[name] === "local" ? "global" : "local",
    }));
  };

  const getScope = (name) => scopes[name] || "global";

  const canHaveLocalScope = (item) => {
    return SCOPE_CATEGORIES.has(item.category) && !GLOBAL_ONLY.has(item.name);
  };

  const selectAllMissing = () => {
    const missing = items.filter((i) => !i.installed).map((i) => i.name);
    setSelected(new Set(missing));
  };

  const handleInstall = () => {
    const installItems = [...selected].map((name) => ({
      name,
      scope: getScope(name),
    }));
    onInstall(installItems);
  };

  const categories = [...new Set(items.map((i) => i.category))];
  const categoryFallbacks = {
    language: "Languages & Runtimes",
    ide: "IDEs & Editors",
    framework: "Frameworks",
    tool: "Tools & Package Managers",
    pkgmanager: "System Package Managers",
  };
  const categoryLabels = {};
  for (const key of Object.keys(categoryFallbacks)) {
    const translated = t(`categories.${key}`);
    categoryLabels[key] = translated.startsWith("categories.") ? categoryFallbacks[key] : translated;
  }

  const installed = items.filter((i) => i.installed).length;
  const missing = items.length - installed;

  // Determine if actions should be disabled
  const actionsDisabled = installing || scanning;

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {/* Fixed top: stats + action buttons */}
      <div className="px-6 pt-4 pb-3 border-b border-[rgba(255,255,255,0.06)]">
        <div className="flex gap-6 text-[13px] mb-3">
          <div className="flex items-center gap-2">
            <div className="w-2.5 h-2.5 rounded-full bg-cr-green" />
            <span className="text-cr-muted font-medium">{installed} {t("scan.installed") || "installed"}</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-2.5 h-2.5 rounded-full bg-cr-red" />
            <span className="text-cr-muted font-medium">{missing} {t("scan.notInstalled") || "not installed"}</span>
          </div>
        </div>

        <div className="flex gap-2">
          <button
            onClick={handleInstall}
            disabled={selected.size === 0 || actionsDisabled}
            className="px-5 py-2.5 bg-white text-black text-[13px] font-semibold rounded-lg hover:bg-gray-200 transition disabled:opacity-20 disabled:cursor-not-allowed flex items-center gap-2"
          >
            {installing ? (
              <>
                <span className="inline-block w-3 h-3 border-2 border-black/30 border-t-black rounded-full animate-spin" />
                {t("install.installing") || "Installing..."}
              </>
            ) : (
              <>
                {t("scan.installSelected") || "Install selected"} {selected.size > 0 && `(${selected.size})`}
              </>
            )}
          </button>
          <button
            onClick={selectAllMissing}
            disabled={actionsDisabled}
            className="px-5 py-2.5 text-cr-text text-[13px] font-medium border border-[rgba(255,255,255,0.12)] rounded-lg hover:bg-white/5 transition disabled:opacity-30 disabled:cursor-not-allowed"
          >
            {t("scan.selectAll") || "Select all missing"}
          </button>
          <button
            onClick={onRescan}
            disabled={actionsDisabled}
            className="px-5 py-2.5 text-cr-muted text-[13px] border border-[rgba(255,255,255,0.08)] rounded-lg hover:bg-white/5 hover:text-cr-text transition disabled:opacity-30 disabled:cursor-not-allowed"
          >
            {scanning ? (t("scan.scanning") || "Scanning...") : (t("scan.rescan") || "Rescan")}
          </button>
        </div>
      </div>

      {/* Scrollable item list */}
      <div className="flex-1 overflow-y-auto px-6 py-4">
        {/* Package Manager Alert Banner */}
        {missingPkgManagers.length > 0 && !pkgBannerDismissed && (
          <div className="mb-4 px-4 py-3 rounded-lg border border-amber-500/20 bg-amber-500/5">
            <div className="flex items-start justify-between gap-3">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1.5">
                  <span className="text-amber-400 text-[13px] font-medium">
                    {t("pkgAlert.title") || "Missing Package Managers"}
                  </span>
                </div>
                <p className="text-[12px] text-cr-muted mb-2.5">
                  {t("pkgAlert.desc") || "The following package managers are not installed. Some software may not be installable without them."}
                </p>
                <div className="flex flex-wrap gap-2">
                  {missingPkgManagers.map((pm) => (
                    <button
                      key={pm}
                      onClick={() => {
                        onInstall([{ name: pm, scope: "global" }]);
                      }}
                      disabled={actionsDisabled}
                      className="px-3 py-1.5 text-[11px] font-medium rounded-md border border-amber-500/30 bg-amber-500/10 text-amber-300 hover:bg-amber-500/20 transition disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      {t("pkgAlert.install") || "Install"} {pm}
                    </button>
                  ))}
                </div>
              </div>
              <button
                onClick={() => setPkgBannerDismissed(true)}
                className="text-cr-muted hover:text-cr-text text-[16px] leading-none mt-0.5 transition"
                title={t("pkgAlert.dismiss") || "Dismiss"}
              >
                ×
              </button>
            </div>
          </div>
        )}
        {categories.map((cat) => {
          const catItems = items.filter((i) => i.category === cat);
          if (catItems.length === 0) return null;

          return (
            <div key={cat} className="mb-6">
              <div className="text-[12px] text-cr-muted uppercase tracking-wider mb-3 font-semibold">
                {categoryLabels[cat] || cat}
              </div>

              <div className="flex flex-col gap-1.5">
                {catItems.map((item) => (
                  <div
                    key={item.name}
                    onClick={() => !item.installed && !actionsDisabled && toggle(item.name)}
                    className={`flex items-center justify-between px-4 py-3 rounded-lg border transition ${
                      actionsDisabled ? "cursor-default" : "cursor-pointer"
                    } ${
                      item.installed
                        ? "border-[rgba(34,197,94,0.30)] bg-[rgba(34,197,94,0.07)] hover:bg-[rgba(34,197,94,0.12)]"
                        : selected.has(item.name)
                          ? "border-[rgba(255,255,255,0.20)] bg-white/5"
                          : "border-[rgba(255,255,255,0.06)] hover:border-[rgba(255,255,255,0.10)] hover:bg-white/[0.03]"
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      {item.installed && (
                        <div className="w-2 h-2 rounded-full bg-cr-green flex-shrink-0" />
                      )}
                      {!item.installed && (
                        <div
                          className={`w-[18px] h-[18px] rounded border flex items-center justify-center text-[11px] transition ${
                            selected.has(item.name)
                              ? "bg-white border-white text-black"
                              : "border-[rgba(255,255,255,0.18)] text-transparent"
                          }`}
                        >
                          ✓
                        </div>
                      )}
                      <span className={`text-[14px] ${item.installed ? "text-white font-medium" : "text-cr-text"}`}>{item.name}</span>
                    </div>

                    <div className="flex items-center gap-3">
                      {/* Local/Global toggle — only for selected non-installed frameworks/tools */}
                      {!item.installed && canHaveLocalScope(item) && selected.has(item.name) && (
                        <button
                          onClick={(e) => toggleScope(e, item.name)}
                          disabled={actionsDisabled}
                          className={`flex items-center text-[11px] font-semibold rounded-full px-3 py-1 border transition ${
                            getScope(item.name) === "local"
                              ? "border-amber-500/30 bg-amber-500/10 text-amber-400"
                              : "border-blue-500/30 bg-blue-500/10 text-blue-400"
                          } hover:opacity-80 disabled:opacity-40`}
                          title={getScope(item.name) === "local"
                            ? (t("scope.localTip") || "Install to current project only")
                            : (t("scope.globalTip") || "Install system-wide (global)")
                          }
                        >
                          {getScope(item.name) === "local"
                            ? (t("scope.local") || "Local")
                            : (t("scope.global") || "Global")
                          }
                        </button>
                      )}

                      <span className={`text-[13px] font-mono font-medium ${item.installed ? "text-cr-green" : "text-cr-muted"}`}>
                        {item.installed
                          ? item.version === "found" ? (t("scan.found") || "found") : item.version
                          : (t("scan.notInstalled") || "not installed")}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
