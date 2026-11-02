type BrandMarkProps = {
  size?: number;
  inverted?: boolean;
};

export function BrandMark({ size = 64, inverted = false }: BrandMarkProps) {
  const radius = size * 0.22;
  return (
    <div
      className={`flex items-center justify-center ${inverted ? "bg-white" : "bg-teal"}`}
      style={{ width: size, height: size, borderRadius: radius }}
      aria-hidden
    >
      <svg
        width={size * 0.52}
        height={size * 0.52}
        viewBox="0 0 24 24"
        fill="none"
        className={inverted ? "text-teal" : "text-white"}
      >
        <path
          d="M8.4 13.6 6.2 11.4a1.8 1.8 0 0 0-2.55 0 1.8 1.8 0 0 0 0 2.55l3.7 3.7c.9.9 2.2 1.15 3.35.7l7.5-2.9a2 2 0 0 0 1.2-2.55 2 2 0 0 0-2.45-1.25l-4.2 1.2"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="m15.6 10.4 2.2-2.2a1.8 1.8 0 0 0 0-2.55 1.8 1.8 0 0 0-2.55 0l-3.7 3.7c-.9.9-1.15 2.2-.7 3.35l.55 1.4"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
}
