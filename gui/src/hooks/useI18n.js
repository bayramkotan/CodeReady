import { useState, useCallback } from "react";
import { translations } from "../i18n/translations";

export function useI18n(defaultLang = "en") {
  const [lang, setLang] = useState(defaultLang);

  const t = useCallback(
    (key) => {
      const keys = key.split(".");
      let value = translations[lang];
      for (const k of keys) {
        value = value?.[k];
      }
      return value || key;
    },
    [lang]
  );

  const toggleLang = useCallback(() => {
    setLang((prev) => (prev === "en" ? "tr" : "en"));
  }, []);

  return { lang, setLang, toggleLang, t };
}
