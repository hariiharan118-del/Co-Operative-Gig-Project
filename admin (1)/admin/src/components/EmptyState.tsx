export function EmptyState({ message }: { message: string }) {
  return (
    <div className="rounded-lg border border-dashed border-border px-4 py-10 text-center text-sm text-muted">
      {message}
    </div>
  );
}

export function ErrorText({ error }: { error: unknown }) {
  if (!error) return null;
  const message = error instanceof Error ? error.message : "Something went wrong";
  return <p className="text-sm text-danger">{message}</p>;
}

export function LoadingRows({ cols }: { cols: number }) {
  return (
    <>
      {Array.from({ length: 6 }).map((_, i) => (
        <tr key={i} className="border-b border-border">
          <td colSpan={cols} className="px-3 py-3">
            <div className="h-3 animate-pulse rounded bg-field" />
          </td>
        </tr>
      ))}
    </>
  );
}
