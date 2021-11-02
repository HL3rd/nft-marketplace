/* src/App.tsx */
import { Component } from 'react';
import { BrowserRouter as Router, Switch, Link } from 'react-router-dom';
import './App.css';

const supportsHistory = "pushState" in window.history;

class App extends Component {
  render() {
    return (
      <div className="App">
        <nav className="border-b p-6">
          <p className="text-4xl font-bold">CryptoCantina</p>
          <Router forceRefresh={!supportsHistory}>
            <Switch>
              <Link
                to="/"
                className="mr-4 text-pink-500"
              >
                Home
              </Link>
              <br />
              <Link
                to="/create-item"
                className="mr-4 text-pink-500"
              >
                Sell an NFT
              </Link>
              <br />
              <Link
                to="/my-assets"
                className="mr-4 text-pink-500"
              >
                My NFTs
              </Link>
              <Link
                to="/dashboard"
                className="mr-4 text-pink-500"
              >
                Dashboard
              </Link>
            </ Switch>
          </Router>
        </nav>
      </div>
    );
  }
}

export default App;
