/* eslint-disable @next/next/no-img-element */

/** IMPACT-365 logo: the mark (white on dark, purple on light) plus the name. */
export function Logo({ light = false }: { light?: boolean }) {
  return (
    <div className="flex items-center gap-3">
      <img
        src={light ? "/logo-mark-white.png" : "/logo-mark-purple.png"}
        alt=""
        width={44}
        height={44}
        className="h-11 w-11 object-contain"
      />
      <div className="leading-tight">
        <div className={`text-lg font-extrabold tracking-wide ${light ? "text-white" : "text-purple"}`}>
          IMPACT-365
        </div>
        <div className="text-[11px] font-medium text-gold">— 1 jour 1 impact —</div>
      </div>
    </div>
  );
}
