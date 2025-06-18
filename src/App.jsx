import { useState } from "react";
import "./App.css";

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="App">
      <header className="App-header">
        <h1>React CI/CD Application</h1>
        <p>Deployed with Terraform and GitHub Actions</p>
        <div className="card">
          <button onClick={() => setCount((count) => count + 1)}>
            count is {count}
          </button>
        </div>
        <div className="status">
          <p>Build Date: {new Date().toLocaleDateString()}</p>
          <p>Environment: Production</p>
        </div>
      </header>
    </div>
  );
}

export default App;
