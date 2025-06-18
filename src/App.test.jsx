import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import App from "./App";

describe("App", () => {
  it("renders headline", () => {
    render(<App />);
    expect(screen.getByText("React CI/CD Application")).toBeInTheDocument();
  });

  it("renders deploy message", () => {
    render(<App />);
    expect(
      screen.getByText("Deployed with Terraform and GitHub Actions")
    ).toBeInTheDocument();
  });
});
