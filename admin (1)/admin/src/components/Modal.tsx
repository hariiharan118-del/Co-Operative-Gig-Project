import { X } from "lucide-react";
import { useEffect } from "react";

type ModalProps = {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
  wide?: boolean;
};

export function Modal({ title, onClose, children, wide }: ModalProps) {
  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-navy/40 p-4 pt-16">
      <div className={`w-full rounded-xl border border-border bg-white shadow-lg ${wide ? "max-w-3xl" : "max-w-lg"}`}>
        <div className="flex items-center justify-between border-b border-border px-4 py-3">
          <h2 className="text-sm font-semibold text-navy">{title}</h2>
          <button type="button" onClick={onClose} className="rounded p-1 text-muted hover:bg-field" aria-label="Close">
            <X size={16} />
          </button>
        </div>
        <div className="p-4">{children}</div>
      </div>
    </div>
  );
}
