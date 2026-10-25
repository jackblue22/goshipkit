import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Button } from "@goshipkit/ui";
import "./styles.css";

function App() {
  return (
    <main className="shell">
      <p className="eyebrow">GoShipKit</p>
      <h1>Small teams, clear progress.</h1>
      <p className="lede">
        One friendly place for projects, tasks, resources, updates, and stakeholder reviews.
      </p>
      <Button>Open workspace</Button>
    </main>
  );
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
