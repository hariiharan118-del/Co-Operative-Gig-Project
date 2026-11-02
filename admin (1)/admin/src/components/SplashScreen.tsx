import { BrandMark } from "./BrandMark";

export function SplashScreen({ fading }: { fading: boolean }) {
  return (
    <div
      className={`fixed inset-0 z-[80] flex flex-col items-center justify-center bg-teal ${fading ? "splash-fade" : ""}`}
    >
      <BrandMark size={76} inverted />
      <p className="mt-4 text-[28px] font-bold tracking-tight text-white">Co-opServe Admin</p>
    </div>
  );
}
