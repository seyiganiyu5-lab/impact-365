import { Flame } from "lucide-react";

export function Logo({ light = false }: { light?: boolean }) {
  return (
    <div className="flex items-center gap-3">
      <div
        className={`flex h-11 w-11 items-center justify-center rounded-full border-4 ${
          light ? "border-white" : "border-purple"
        }`}
      >
        <Flame className="h-5 w-5 text-gold" fill="currentColor" />
      </div>
      <div className="leading-tight">
        <div className={`text-lg font-extrabold tracking-wide ${light ? "text-white" : "text-purple"}`}>
          IMPACT-365
        </div>
        <div className="text-[11px] font-medium text-gold">— 1 jour 1 impact —</div>
      </div>
    </div>
  );
}
