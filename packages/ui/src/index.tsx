import type { ButtonHTMLAttributes, PropsWithChildren } from "react";

export function Button({ children, style, ...props }: PropsWithChildren<ButtonHTMLAttributes<HTMLButtonElement>>) {
  return (
    <button
      {...props}
      style={{
        width: "fit-content",
        border: 0,
        borderRadius: 999,
        padding: ".8rem 1.2rem",
        color: "white",
        background: "#176b5b",
        cursor: "pointer",
        font: "inherit",
        fontWeight: 700,
        ...style,
      }}
    >
      {children}
    </button>
  );
}
