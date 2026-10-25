import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Button } from "@goshipkit/ui";

function DesktopApp() {
  return (
    <main style={{ padding: 32, fontFamily: "system-ui" }}>
      <h1>GoShipKit Desktop</h1>
      <p>The desktop client connects to your self-hosted GoShipKit server.</p>
      <Button>Configure server</Button>
    </main>
  );
}

createRoot(document.getElementById("root")!).render(<StrictMode><DesktopApp /></StrictMode>);
